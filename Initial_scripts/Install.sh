#!/bin/bash

mkdir -p /home/nelson/Documentos/Ubuntu_master
mkdir -p /opt/snn_trials/lockstep_ws/src/snn_lockstep
mkdir -p /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/freefloating_gazebo
mkdir -p /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/foil_dynamics_plugin

cd /home/nelson/Documentos/Ubuntu_master
git clone --no-checkout https://github.com/alejandropetit/LIFNeuralNetwork.git .
git sparse-checkout init --cone
git sparse-checkout set simulator SNN_Codes Initial_scripts routes
git checkout


cp -a /home/nelson/Documentos/Ubuntu_master/simulator/lockstep_src/. /opt/snn_trials/lockstep_ws/src/snn_lockstep
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_control_heading.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/sailboat_control_heading.py # usv_base_ctrl
cp /home/nelson/Documentos/Ubuntu_master/simulator/patrol_pid_scene2.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_navigation/scripts/patrol_pid_scene2.py #usv_navigation
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_scenario2.launch /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/launch/scenarios_launchs/sailboat_scenario2.launch #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_scenario2.xml /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/scenes/sailboat_scenario2.xml #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/empty_accelerated.world /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/world/empty_accelerated.world #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat.xacro /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/xacro/sailboat.xacro #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/boat_subdivided4.xacro /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/xacro/boat_subdivided4.xacro #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/communicate_virtual.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/communicate.py # usv_base_ctrl
cp /home/nelson/Documentos/Ubuntu_master/simulator/spawn_sailboat.launch /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/launch/models/spawn_sailboat.launch
cp /home/nelson/Documentos/Ubuntu_master/simulator/foil_dynamics_plugin.cpp /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/
cp /home/nelson/Documentos/Ubuntu_master/simulator/foil_dynamics_plugin.h /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/foil_dynamics_plugin/
cp /home/nelson/catkin_ws/src/usv_sim_lsa/freefloating_gazebo_resources/freefloating_gazebo/src/freefloating_pids.cpp /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/
cp /home/nelson/catkin_ws/src/usv_sim_lsa/freefloating_gazebo_resources/freefloating_gazebo/src/freefloating_pids_joint.cpp /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/
cp /home/nelson/catkin_ws/src/usv_sim_lsa/freefloating_gazebo_resources/freefloating_gazebo/include/freefloating_gazebo/freefloating_pids.h /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/freefloating_gazebo/
cp /home/nelson/catkin_ws/src/usv_sim_lsa/freefloating_gazebo_resources/freefloating_gazebo/include/freefloating_gazebo/freefloating_pids_joint.h /opt/snn_trials/lockstep_ws/src/snn_lockstep/vendor/include/freefloating_gazebo/

cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/start_experiment_D.sh /home/nelson/start_experiment.sh
cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/Velero.sh /home/nelson/Velero.sh
cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/Puerto_serie.sh /home/nelson
cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/Anaconda.sh /home/nelson/Anaconda.sh
cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/sail_init.sh /home/nelson/sail_init.sh

chmod +x /home/nelson/start_experiment.sh
chmod +x /home/nelson/Velero.sh 
chmod +x /home/nelson/Puerto_serie.sh 
chmod +x /home/nelson/Anaconda.sh
chmod +x /home/nelson/sail_init.sh

source /opt/ros/kinetic/setup.bash
cd /home/nelson/catkin_ws

catkin_make_isolated --pkg usv_base_ctrl --install
catkin_make_isolated --pkg usv_sim --install
catkin_make_isolated --pkg usv_navigation --install

source /opt/ros/kinetic/setup.bash
source /home/nelson/catkin_ws/install_isolated/setup.bash

catkin_make -C /opt/snn_trials/lockstep_ws -j2 -l2 -DPYTHON_EXECUTABLE=/usr/bin/python2.7 -DCMAKE_BUILD_TYPE=Release

source /home/nelson/anaconda3/etc/profile.d/conda.sh
conda install pyserial




