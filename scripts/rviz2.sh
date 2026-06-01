#!/bin/bash
# Launch RViz2 from the RoboStack conda env with the correct environment.
# Run from the project root: ./scripts/rviz2.sh
#
# Why a wrapper:
#   - 'conda activate ros2' sets AMENT_PREFIX_PATH, ROS_DISTRO, etc.
#     Running rviz2 directly (without activation) crashes with
#     "AMENT_PREFIX_PATH is not set or empty".
#   - We replicate the needed vars here so no manual conda activate is required.
#   - PYTHONPATH is kept pointing to the conda env's Python 3.11 packages
#     (rviz2 needs it for Python plugins) but Homebrew's Python must not
#     appear before the conda env in PATH.

CONDA_ENV="/Users/rustam/miniforge3/envs/ros2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CYCLONE_CONFIG="$SCRIPT_DIR/../config/cyclonedds_macos.xml"

if [ ! -x "$CONDA_ENV/bin/rviz2" ]; then
  echo "ERROR: rviz2 not found in $CONDA_ENV/bin/"
  echo "Install with: mamba install ros-humble-rviz2"
  exit 1
fi

if ! pgrep -f "zenoh-bridge-ros2dds" > /dev/null 2>&1; then
  echo "WARNING: Zenoh bridge is not running. Topics from Docker will not be visible."
  echo "         Run ./scripts/start_bridge.sh first."
fi

AMENT_PREFIX_PATH="$CONDA_ENV" \
ROS_DISTRO=humble \
PYTHONPATH="$CONDA_ENV/lib/python3.11/site-packages" \
PATH="$CONDA_ENV/bin:$PATH" \
ROS_DOMAIN_ID=42 \
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp \
CYCLONEDDS_URI="$CYCLONE_CONFIG" \
"$CONDA_ENV/bin/rviz2" "$@"
