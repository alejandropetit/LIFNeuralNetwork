#!/bin/bash
set -e
: "${SNN_SEED:?Source /home/nelson/experiment_config.sh before starting Gazebo}"

source /opt/ros/kinetic/setup.bash
source /home/nelson/catkin_ws/install_isolated/setup.bash
source /opt/snn_trials/lockstep_ws/devel/setup.bash

export GAZEBO_PLUGIN_PATH="/opt/snn_trials/lockstep_ws/devel/lib:${GAZEBO_PLUGIN_PATH:-}"

cd /home/nelson/catkin_ws

roslaunch usv_sim sailboat_scenario2.launch parse:=true

echo "Gazebo seed: $SNN_SEED"
exec roslaunch usv_sim sailboat_scenario2.launch parse:=false seed:="$SNN_SEED"
