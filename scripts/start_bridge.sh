#!/bin/bash
# Starts both sides of the Zenoh bridge:
#   1. Router inside the Docker container (listens on port 7447)
#   2. Client on macOS (connects to localhost:7447 via Docker port-forward)
#
# Keep this script running in a dedicated terminal.
# Ctrl+C stops the macOS client; the Docker router keeps running until
# the container is stopped with: docker compose down

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRIDGE="$SCRIPT_DIR/../bin/zenoh-bridge-ros2dds"

if [ ! -x "$BRIDGE" ]; then
  echo "ERROR: $BRIDGE not found. Run scripts/download_zenoh.sh first."
  exit 1
fi

# Verify container is running
if ! docker inspect ros2_dev > /dev/null 2>&1; then
  echo "ERROR: container ros2_dev is not running. Run: docker compose up -d"
  exit 1
fi

# Kill any stale macOS bridge process
pkill -f "zenoh-bridge-ros2dds" 2>/dev/null || true
sleep 0.3

# Step 1 — start Zenoh router inside Docker
echo "[1/2] Starting Zenoh router inside Docker container..."
docker exec -d ros2_dev bash -c "
  ROS_DISTRO=humble \
  zenoh-bridge-ros2dds router \
    --listen tcp/0.0.0.0:7447 \
    --no-multicast-scouting \
    --domain 42 \
    > /tmp/zenoh_router.log 2>&1"

# Give the router a moment to bind the port
sleep 2

CYCLONE_CONFIG="$SCRIPT_DIR/../config/cyclonedds_macos.xml"

echo "[2/2] Starting Zenoh client bridge on macOS (connecting to localhost:7447)..."
ROS_DOMAIN_ID=42 \
ROS_DISTRO=humble \
CYCLONEDDS_URI="$CYCLONE_CONFIG" \
"$BRIDGE" client \
  --connect tcp/localhost:7447 \
  --no-multicast-scouting \
  --domain 42
