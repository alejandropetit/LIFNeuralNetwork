#!/bin/bash

mkdir -p /home/nelson/Documentos/Ubuntu_master
cd /home/nelson/Documentos/Ubuntu_master
git clone --no-checkout https://github.com/alejandropetit/LIFNeuralNetwork.git .
git sparse-checkout init --cone
git sparse-checkout set simulator SNN_Codes Initial_scripts
git checkout

cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_control_heading_fpga.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/sailboat_control_heading.py # usv_base_ctrl
cp /home/nelson/Documentos/Ubuntu_master/simulator/foil_dynamics_plugin.cpp /home/nelson/catkin_ws/src/usv_sim_lsa/usv_dynamics/foil_dynamics_plugin/src/foil_dynamics_plugin.cpp 
cp /home/nelson/Documentos/Ubuntu_master/simulator/foil_dynamics_plugin.h /home/nelson/catkin_ws/src/usv_sim_lsa/usv_dynamics/foil_dynamics_plugin/include/foil_dynamics_plugin/foil_dynamics_plugin.h
cp /home/nelson/Documentos/Ubuntu_master/simulator/patrol_pid_scene2.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_navigation/scripts/patrol_pid_scene2.py #usv_navigation
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_scenario2.launch /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/launch/scenarios_launchs/sailboat_scenario2.launch #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_scenario2.xml /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/scenes/sailboat_scenario2.xml #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/empty_accelerated.world /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/world/empty_accelerated.world #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat.xacro /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/xacro/sailboat.xacro #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/boat_subdivided4.xacro /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/xacro/boat_subdivided4.xacro #usv_sim
cp /home/nelson/Documentos/Ubuntu_master/simulator/communicate_fpga.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/communicate.py # usv_base_ctrl
cp /home/nelson/Documentos/Ubuntu_master/simulator/text_file.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/text_file.py # usv_base_ctrl

cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/sail_init.sh /home/nelson/sail_init.sh
chmod +x /home/nelson/sail_init.sh

source /opt/ros/kinetic/setup.bash
cd /home/nelson/catkin_ws
catkin_make_isolated --pkg foil_dynamics_plugin --install
catkin_make_isolated --pkg usv_base_ctrl --install
catkin_make_isolated --pkg usv_sim --install
catkin_make_isolated --pkg usv_navigation --install