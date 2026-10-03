#!/bin/bash
set -e

source /opt/ros/kinetic/setup.bash
source /home/nelson/catkin_ws/install_isolated/setup.bash
source /opt/snn_trials/lockstep_ws/devel/setup.bash

export GAZEBO_PLUGIN_PATH="/opt/snn_trials/lockstep_ws/devel/lib:${GAZEBO_PLUGIN_PATH:-}"

cd /home/nelson/catkin_ws

roslaunch usv_sim sailboat_scenario2.launch parse:=true

exec roslaunch usv_sim sailboat_scenario2.launch parse:=false seed:=42
