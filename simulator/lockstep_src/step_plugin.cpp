#include <gazebo/gazebo.hh>
#include <gazebo/physics/physics.hh>
#include <ros/ros.h>
#include <ros/callback_queue.h>
#include <snn_lockstep/Step.h>
#include <snn_lockstep/SetSail.h>
#include <freefloating_gazebo/freefloating_pids_joint.h>
#include <atomic>
#include <cmath>
#include <mutex>
#include <thread>
#include <stdexcept>

namespace gazebo {
class SnnStepPlugin : public ModelPlugin {
  physics::ModelPtr model_;
  physics::WorldPtr world_;
  std::unique_ptr<ros::NodeHandle> node_;
  ros::CallbackQueue queue_;
  ros::ServiceServer service_;
  std::thread worker_;
  std::atomic<bool> running_{false};
  event::ConnectionPtr update_;
  std::mutex mutex_;
  FreeFloatingJointPids pid_;
  std::vector<physics::JointPtr> joints_;
  sensor_msgs::JointState measure_, effort_;
  bool initialized_ = false;
  uint64_t steps_ = 0, sequence_ = 0;
  unsigned int pid_stride_ = 0;
  double step_size_ = 0;
  std::string update_error_;

  void Initialize() {
    if (initialized_ || world_->GetSimTime().Double() != 0)
      throw std::runtime_error("Initialize requires a fresh, paused simulation at t=0");
    ros::NodeHandle control("/sailboat/controllers");
    if (control.hasParam("config/body"))
      throw std::runtime_error("Lockstep currently supports joint control only");
    bool cascaded = true, dynamic = true;
    control.param("config/joints/cascaded_position", cascaded, true);
    control.param("config/joints/dynamic_reconfigure", dynamic, true);
    if (cascaded || dynamic)
      throw std::runtime_error("Expected fixed non-cascaded position PIDs");
    if (!control.getParam("config/joints/name", measure_.name) || (measure_.name.size() < 2 || measure_.name.size() > 3))
      throw std::runtime_error("Expected the original joint PID configuration");
    for (const auto &name : measure_.name) {
      auto joint = model_->GetJoint(name);
      if (!joint) throw std::runtime_error("Missing joint: " + name);
      joints_.push_back(joint);
    }
    step_size_ = world_->GetPhysicsEngine()->GetMaxStepSize();
    pid_stride_ = static_cast<unsigned int>(std::lround(0.01 / step_size_));
    if (!pid_stride_ || std::abs(pid_stride_ * step_size_ - 0.01) > 1e-12)
      throw std::runtime_error("Physics dt must divide the original 0.01 s PID period");
    model_->SetWorldPose(math::Pose(240, 100, 0, 0, 0, 0));
    model_->SetLinearVel(math::Vector3::Zero);
    model_->SetAngularVel(math::Vector3::Zero);
    for (auto &joint : joints_) {
      joint->SetPosition(0, 0);
      joint->SetVelocity(0, 0);
    }
    ros::Duration dt(0.01);
    pid_.Init(control, dt); // Original PID implementation, filters, gains and clamps.
    measure_.position.resize(joints_.size());
    measure_.velocity.resize(joints_.size());
    effort_.name = measure_.name;
    effort_.effort.assign(joints_.size(), 0.0);
    initialized_ = true;
  }

  void Update() {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!initialized_ || !update_error_.empty()) return;
    try {
      if (steps_ % pid_stride_ == 0) {
        for (size_t i = 0; i < joints_.size(); ++i) {
          measure_.position[i] = joints_[i]->GetAngle(0).Radian();
          measure_.velocity[i] = joints_[i]->GetVelocity(0);
        }
        pid_.MeasureCallBack(boost::make_shared<sensor_msgs::JointState>(measure_));
        if (!pid_.UpdatePID()) throw std::runtime_error("PID has no setpoint/state");
        effort_ = pid_.EffortCommand();
      }
      for (size_t i = 0; i < joints_.size(); ++i) {
        if (!std::isfinite(effort_.effort[i])) throw std::runtime_error("Non-finite PID effort");
        joints_[i]->SetForce(0, effort_.effort[i]);
      }
      ++steps_;
    } catch (const std::exception &error) { update_error_ = error.what(); }
  }

  void Snapshot(snn_lockstep::Step::Response &response) {
    auto pose = model_->GetWorldPose();
    response.pose.position.x = pose.pos.x;
    response.pose.position.y = pose.pos.y;
    response.pose.position.z = pose.pos.z;
    response.pose.orientation.x = pose.rot.x;
    response.pose.orientation.y = pose.rot.y;
    response.pose.orientation.z = pose.rot.z;
    response.pose.orientation.w = pose.rot.w;
    auto linear = model_->GetRelativeLinearVel();
    auto angular = model_->GetRelativeAngularVel();
    response.twist.linear.x = linear.x;
    response.twist.linear.y = linear.y;
    response.twist.linear.z = linear.z;
    response.twist.angular.x = angular.x;
    response.twist.angular.y = angular.y;
    response.twist.angular.z = angular.z;
    auto time = world_->GetSimTime();
    response.sim_time = ros::Time(time.sec, time.nsec);
    response.sequence = sequence_;
    response.iteration = steps_;
    response.step_size = step_size_;
    response.joints.name = measure_.name;
    for (auto &joint : joints_) {
      response.joints.position.push_back(joint->GetAngle(0).Radian());
      response.joints.velocity.push_back(joint->GetVelocity(0));
    }
  }

  bool Step(snn_lockstep::Step::Request &request, snn_lockstep::Step::Response &response) {
    try {
      if (!world_->IsPaused()) throw std::runtime_error("World must remain paused");
      if (request.initialize) {
        std::lock_guard<std::mutex> guard(mutex_);
        if (request.sequence || request.steps) throw std::runtime_error("Invalid initialization request");
        Initialize();
        Snapshot(response);
      } else {
        if (!initialized_ || request.sequence != sequence_ + 1 || !request.steps || request.steps > 100000)
          throw std::runtime_error("Invalid step count or sequence; requests must not be retried");
        for (double angle : {request.rudder, request.sail, request.sail2})
          if (!std::isfinite(angle) || std::abs(angle) > M_PI)
            throw std::runtime_error("Invalid action angle");
        // Each foil plugin acknowledges the new limit while physics is paused.
        for (const auto &joint : {"sail_joint", "sail_joint_2"}) {
          snn_lockstep::SetSail sail;
          sail.request.angle = request.sail; // Original /sail/angleLimits drives both sails.
          auto client = node_->serviceClient<snn_lockstep::SetSail>(std::string("/snn_step/") + joint);
          if (!client.call(sail) || !sail.response.success)
            throw std::runtime_error("Sail did not acknowledge the action");
        }
        {
          std::lock_guard<std::mutex> guard(mutex_);
          sensor_msgs::JointState setpoint;
          setpoint.name = {"rudder_joint", "sail_joint", "sail_joint_2"};
          setpoint.position = {request.rudder, request.sail, request.sail2};
          pid_.SetpointCallBack(boost::make_shared<sensor_msgs::JointState>(setpoint));
        }
        const uint64_t before = steps_;
        world_->Step(request.steps); // Blocking Gazebo 7 API, outside the physics callback.
        std::lock_guard<std::mutex> guard(mutex_);
        if (!world_->IsPaused() || steps_ != before + request.steps || !update_error_.empty())
          throw std::runtime_error("Incomplete physics step: " + update_error_);
        sequence_ = request.sequence;
        Snapshot(response);
      }
      response.success = true;
    } catch (const std::exception &error) {
      response.success = false;
      response.status_message = error.what();
    }
    return true;
  }

public:
  void Load(physics::ModelPtr model, sdf::ElementPtr) override {
    model_ = model;
    world_ = model->GetWorld();
    node_.reset(new ros::NodeHandle("/snn_step"));
    node_->setCallbackQueue(&queue_);
    service_ = node_->advertiseService("advance", &SnnStepPlugin::Step, this);
    update_ = event::Events::ConnectWorldUpdateBegin(boost::bind(&SnnStepPlugin::Update, this));
    running_ = true;
    worker_ = std::thread([this] {
      while (running_ && ros::ok()) queue_.callAvailable(ros::WallDuration(0.01));
    });
  }
  ~SnnStepPlugin() override {
    running_ = false;
    queue_.disable();
    if (worker_.joinable()) worker_.join();
    update_.reset();
  }
};
GZ_REGISTER_MODEL_PLUGIN(SnnStepPlugin)
}
