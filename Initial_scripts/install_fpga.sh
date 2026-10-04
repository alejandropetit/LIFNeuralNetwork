#!/bin/bash
set -e

mkdir -p /home/nelson/Documentos/Ubuntu_master
mkdir -p /opt/snn_trials/lockstep_ws/src/snn_lockstep
mkdir -p /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/freefloating_gazebo
mkdir -p /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/foil_dynamics_plugin

cd /home/nelson/Documentos/Ubuntu_master
git clone --no-checkout https://github.com/alejandropetit/LIFNeuralNetwork.git .
git sparse-checkout init --cone
git sparse-checkout set simulator SNN_Codes Initial_scripts routes FPGA/scripts
git checkout


cp -a /home/nelson/Documentos/Ubuntu_master/simulator/lockstep_src/. /opt/snn_trials/lockstep_ws/src/snn_lockstep/

cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_control_heading_fpga.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/sailboat_control_heading.py
cp /home/nelson/Documentos/Ubuntu_master/simulator/communicate_fpga.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/communicate.py
cp /home/nelson/Documentos/Ubuntu_master/SNN_Codes/Spiking_codes/text_file.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/text_file.py

cp /home/nelson/Documentos/Ubuntu_master/simulator/patrol_pid_scene2.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_navigation/scripts/patrol_pid_scene2.py
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_scenario2.launch /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/launch/scenarios_launchs/sailboat_scenario2.launch
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_scenario2.xml /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/scenes/sailboat_scenario2.xml
cp /home/nelson/Documentos/Ubuntu_master/simulator/empty_accelerated.world /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/world/empty_accelerated.world
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat.xacro /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/xacro/sailboat.xacro
cp /home/nelson/Documentos/Ubuntu_master/simulator/boat_subdivided4.xacro /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/xacro/boat_subdivided4.xacro
cp /home/nelson/Documentos/Ubuntu_master/simulator/spawn_sailboat.launch /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/launch/models/spawn_sailboat.launch


cp /home/nelson/Documentos/Ubuntu_master/simulator/foil_dynamics_plugin.cpp /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/
cp /home/nelson/Documentos/Ubuntu_master/simulator/foil_dynamics_plugin.h /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/foil_dynamics_plugin/

cp /home/nelson/catkin_ws/src/usv_sim_lsa/freefloating_gazebo_resources/freefloating_gazebo/src/freefloating_pids.cpp /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/
cp /home/nelson/catkin_ws/src/usv_sim_lsa/freefloating_gazebo_resources/freefloating_gazebo/src/freefloating_pids_joint.cpp /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/
cp /home/nelson/catkin_ws/src/usv_sim_lsa/freefloating_gazebo_resources/freefloating_gazebo/include/freefloating_gazebo/freefloating_pids.h /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/freefloating_gazebo/
cp /home/nelson/catkin_ws/src/usv_sim_lsa/freefloating_gazebo_resources/freefloating_gazebo/include/freefloating_gazebo/freefloating_pids_joint.h /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/freefloating_gazebo/


cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/Velero.sh /home/nelson/Velero.sh
cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/experiment_config.sh /home/nelson/experiment_config.sh
cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/sail_init.sh /home/nelson/sail_init.sh

chmod +x /home/nelson/Velero.sh
chmod +x /home/nelson/sail_init.sh
chmod +x /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/sailboat_control_heading.py

mkdir -p /home/nelson/Documentos/Ubuntu_master/SNN_Codes/Spiking_codes/data_result


source /opt/ros/kinetic/setup.bash
cd /home/nelson/catkin_ws

catkin_make_isolated --pkg usv_base_ctrl --install -DPYTHON_EXECUTABLE=/usr/bin/python2.7
catkin_make_isolated --pkg usv_sim --install -DPYTHON_EXECUTABLE=/usr/bin/python2.7
catkin_make_isolated --pkg usv_navigation --install -DPYTHON_EXECUTABLE=/usr/bin/python2.7


source /opt/ros/kinetic/setup.bash
source /home/nelson/catkin_ws/install_isolated/setup.bash

catkin_make -C /opt/snn_trials/lockstep_ws -j2 -l2 -DPYTHON_EXECUTABLE=/usr/bin/python2.7 -DCMAKE_BUILD_TYPE=Release

source /opt/snn_trials/lockstep_ws/devel/setup.bash

/usr/bin/python2.7 -c "import serial; from snn_lockstep.srv import StepRequest; StepRequest(initial_x=50.0, initial_y=80.0, initial_yaw=0.0)"
