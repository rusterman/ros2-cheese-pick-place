#!/bin/bash
# Wrapper: run any 'ros2 ...' command on macOS with the correct environment.
#
# Usage:
#   ./scripts/ros2.sh topic list
#   ./scripts/ros2.sh topic echo /hello_topic
#   ./scripts/ros2.sh topic hz /hello_topic
#   ./scripts/ros2.sh node list
#
# Why this wrapper is needed:
#   1. Homebrew Python (3.14+) leaks into PATH and breaks rclpy's C extension loading.
#      Fix: unset PYTHONPATH and use the conda env's Python directly.
#   2. The ros2 CLI tries the daemon first via XML-RPC; if it times out, the command
#      hangs for ~8-60 s. Fix: pass --no-daemon to verbs that support it.
#      NOTE: streaming verbs (hz, bw, delay) do NOT support --no-daemon — they never
#      use the daemon, so no flag is needed for them.
#   3. CycloneDDS must use lo0 (loopback) to match the Zenoh bridge's DDS interface.
#      Fix: ROS_LOCALHOST_ONLY=1 and RMW_IMPLEMENTATION=rmw_cyclonedds_cpp.

CONDA_ENV="/Users/rustam/miniforge3/envs/ros2"
ROS2_BIN="$CONDA_ENV/bin/ros2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CYCLONE_CONFIG="$SCRIPT_DIR/../config/cyclonedds_macos.xml"

if [ ! -x "$ROS2_BIN" ]; then
  echo "ERROR: $ROS2_BIN not found. Is the ros2 conda environment installed?"
  exit 1
fi

if ! pgrep -f "zenoh-bridge-ros2dds" > /dev/null 2>&1; then
  echo "WARNING: Zenoh bridge is not running — topics from Docker will not be visible."
  echo "         Run ./scripts/start_bridge.sh in a separate terminal first."
fi

SUBCOMMAND="${1:-}"
VERB="${2:-}"

# Verbs that query the graph (use NodeStrategy) and therefore support --no-daemon.
# Streaming/processing verbs (hz, bw, delay, pub) handle their own DDS node and
# do not accept --no-daemon.
daemon_flag() {
  case "$SUBCOMMAND/$VERB" in
    topic/list|topic/echo|topic/info|topic/find|topic/type) echo "--no-daemon" ;;
    node/list|node/info)                                     echo "--no-daemon" ;;
    service/list|service/type|service/find|service/call)     echo "--no-daemon" ;;
    action/list|action/info)                                 echo "--no-daemon" ;;
    param/list|param/get|param/set|param/dump)               echo "--no-daemon" ;;
    *)                                                        echo "" ;;
  esac
}

EXTRA=$(daemon_flag)

PYTHONPATH="" \
PATH="$CONDA_ENV/bin:$PATH" \
ROS_DOMAIN_ID=42 \
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp \
CYCLONEDDS_URI="$CYCLONE_CONFIG" \
"$ROS2_BIN" "$@" $EXTRA
