#!/bin/bash

mkdir -p /home/nelson/Documentos/Ubuntu_master
cd /home/nelson/Documentos/Ubuntu_master
git clone https://github.com/alejandropetit/LIFNeuralNetwork.git .

cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_control_heading.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/sailboat_control_heading.py
cp /home/nelson/Documentos/Ubuntu_master/simulator/foil_dynamics_plugin.cpp /home/nelson/catkin_ws/src/usv_sim_lsa/usv_dynamics/foil_dynamics_plugin/src/foil_dynamics_plugin.cpp
cp /home/nelson/Documentos/Ubuntu_master/simulator/foil_dynamics_plugin.h /home/nelson/catkin_ws/src/usv_sim_lsa/usv_dynamics/foil_dynamics_plugin/include/foil_dynamics_plugin/foil_dynamics_plugin.h
cp /home/nelson/Documentos/Ubuntu_master/simulator/patrol_pid_scene2.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_navigation/scripts/patrol_pid_scene2.py
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_scenario2.launch /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/launch/scenarios_launchs/sailboat_scenario2.launch
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat_scenario2.xml /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/scenes/sailboat_scenario2.xml
cp /home/nelson/Documentos/Ubuntu_master/simulator/empty_accelerated.world /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/world/empty_accelerated.world
cp /home/nelson/Documentos/Ubuntu_master/simulator/sailboat.xacro /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/xacro/sailboat.xacro
cp /home/nelson/Documentos/Ubuntu_master/simulator/boat_subdivided4.xacro /home/nelson/catkin_ws/src/usv_sim_lsa/usv_sim/xacro/boat_subdivided4.xacro
cp /home/nelson/Documentos/Ubuntu_master/simulator/communicate.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/communicate.py
cp /home/nelson/Documentos/Ubuntu_master/simulator/text_file.py /home/nelson/catkin_ws/src/usv_sim_lsa/usv_base_ctrl/scripts/text_file.py

cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/start_experiment_D.sh /home/nelson/start_experiment.sh
cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/Velero_D.sh /home/nelson/Velero.sh
cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/Puerto_serie.sh /home/nelson
cp /home/nelson/Documentos/Ubuntu_master/Initial_scripts/Anaconda_D.sh /home/nelson/Anaconda.sh

conda install pyserial


