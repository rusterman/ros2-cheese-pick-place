# ros2-cheese-pick-place

A ROS2 robotic system for **detecting, picking, and placing cheese slices into a moving grid container** using computer vision and motion planning. Built with a fully containerized architecture that runs on **macOS (Apple Silicon / M chips)** out of the box.

> **Status:** Active development — infrastructure complete, xArm6 robot model integrated and animated in Foxglove, perception pipeline and manipulation in progress.

---

## What This Project Does

A conveyor belt carries cheese slices at constant speed. A camera detects each slice and estimates its 3D pose. The robot arm picks each piece and places it into the correct grid slot of a moving container — in real time, without stopping the belt.

```
Orbbec Astra camera
    │
    ▼
Point cloud processing (PCL — geometric detection, no AI)
    │
    ▼
Conveyor state estimator (position tracking via belt speed)
    │
    ▼
Task scheduler (feasibility check, deadline-based queue)
    │
    ▼
MoveIt2 motion planner (IK + collision-aware trajectories)
    │
    ▼
xArm6 robot arm + mechanical gripper
    │
    ▼
Cheese placed into correct grid slot
```

---

## Technology Stack

| Layer | Technology |
|---|---|
| Robot middleware | ROS2 Humble |
| Robot hardware | UFACTORY xArm6 (6-DOF collaborative arm) |
| Gripper | Mechanical parallel gripper with widened fingertips |
| Camera | Orbbec Astra Series (structured light, RGB-D) |
| Visualization | Foxglove Studio (via WebSocket bridge) |
| Computer vision | OpenCV + PCL (geometric detection, no AI/ML) |
| Motion planning | MoveIt2 |
| Container runtime | Docker (linux/arm64 — M chip native) |
| macOS bridge | Zenoh (TCP bridge over Docker port-forward) |

**No Gazebo, no AI/ML.** The real xArm6 hardware is available from day one. Foxglove replaces Gazebo for visualization. Object detection uses geometric PCL processing — sufficient for geometrically consistent cheese slices within a batch.

---

## Architecture

### System Overview

```
macOS (Apple Silicon)
├── Foxglove Studio           ← connects via WebSocket ws://localhost:8765
├── ros2 CLI                  ← topic inspection, node management
├── zenoh-bridge (client)     ← bridges DDS over TCP
│       │
│       └── TCP localhost:7447
│
Docker container: ros2_dev    (linux/arm64)
├── foxglove_bridge           ← WebSocket server :8765
├── zenoh-bridge (router)     ← port 7447
├── robot_state_publisher     ← publishes TF from xArm6 URDF
├── arm_demo                  ← animated joint state publisher (demo)
└── /ros2_ws/src/
```

### Current Node Graph

```
arm_demo ──/joint_states──► robot_state_publisher ──/tf──► Foxglove 3D panel
foxglove_bridge ──ws:8765──► Foxglove Studio
```

### Why Docker + Zenoh on macOS

Docker Desktop on macOS runs containers inside a Linux VM. The container's bridge IP is unreachable from the host, so raw DDS does not work across the boundary. Zenoh bridges ROS2 topics over TCP — which Docker port-forwarding supports cleanly. Foxglove connects via WebSocket — no X11 or display server required.

---

## Repository Structure

```
.
├── Dockerfile                  # ros:humble + colcon + zenoh-bridge + robot-state-publisher
├── docker-compose.yml          # ports 7447 (zenoh) and 8765 (foxglove)
├── src/
│   ├── xarm_description/       # xArm6 URDF, meshes, launch, demo nodes
│   │   ├── urdf/
│   │   │   └── xarm6_with_gripper.urdf
│   │   ├── meshes/xarm6/
│   │   │   ├── visual/         # STL files for Foxglove rendering
│   │   │   └── collision/      # OBJ files for collision detection
│   │   ├── launch/
│   │   │   └── display.launch.py
│   │   ├── xarm_description/
│   │   │   ├── arm_demo.py     # animated demo — rotates arm, opens/closes gripper
│   │   │   └── joint_state_pub.py  # static hold-up pose publisher
│   │   ├── package.xml
│   │   └── setup.py
│   ├── xarm_gripper/           # xArm gripper STL meshes
│   │   ├── meshes/             # fingers, knuckles
│   │   ├── package.xml
│   │   └── setup.py
│   ├── hello_ros2/             # Python scaffold (publisher, subscriber, marker)
│   └── hello_cpp/              # C++ scaffold (publisher, subscriber)
├── xarm/                       # Original URDF files from UFACTORY (reference, not used in build)
├── config/
│   └── cyclonedds_macos.xml    # CycloneDDS loopback config
├── bin/                        # gitignored — populated by download_zenoh.sh
│   └── zenoh-bridge-ros2dds
├── scripts/
│   ├── download_zenoh.sh       # downloads macOS Zenoh bridge binary (run once)
│   ├── start_bridge.sh         # starts Docker router + macOS client bridge
│   └── ros2.sh                 # ros2 CLI wrapper (fixes Homebrew Python conflict)
└── docs/
    ├── ARCHITECTURE.md         # full system architecture document
    └── ...
```

---

## Prerequisites

- **Docker Desktop for Mac** (Apple Silicon) — [download](https://www.docker.com/products/docker-desktop/)
- **Foxglove Studio** — [download](https://foxglove.dev/download)
- **Miniforge** with a `ros2` conda environment (RoboStack, ROS2 Humble) — for macOS CLI only

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/rusterman/ros2-cheese-pick-place.git
cd ros2-cheese-pick-place

# 2. Download the macOS Zenoh bridge binary (run once)
./scripts/download_zenoh.sh

# 3. Build and start container
docker compose build
docker compose up -d
```

---

## Visualizing the xArm6 in Foxglove (Animated Demo)

Launch order matters — start each in a separate terminal and keep them running.

```bash
# Terminal 1 — build xarm packages (first time or after code changes)
docker exec ros2_dev bash -c "
  source /opt/ros/humble/setup.bash &&
  cd /ros2_ws &&
  colcon build --packages-select xarm_description xarm_gripper"

# Terminal 2 — robot state publisher (computes TF from joint states + URDF)
docker exec -it ros2_dev bash -c "
  source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash &&
  ros2 launch xarm_description display.launch.py"

# Terminal 3 — foxglove bridge (WebSocket server for Foxglove Studio)
docker exec -it ros2_dev bash -c "
  source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash &&
  ros2 launch foxglove_bridge foxglove_bridge_launch.xml port:=8765"

# Terminal 4 — arm demo (animated joint states: arm rotation + gripper open/close)
docker exec -it ros2_dev bash -c "
  source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash &&
  ros2 run xarm_description arm_demo"
```

### Foxglove Studio Setup

1. Open Foxglove Studio
2. **Open Connection** → **Foxglove WebSocket** → `ws://localhost:8765` → **Open**
3. Set **Display frame** → `world`
4. **Custom layers** → **+** → **URDF**
   - URL: `package://xarm_description/urdf/xarm6_with_gripper.urdf`
   - Control mode: `Transforms`
5. **Scene** → **Mesh "up" axis** → `Y-up`

The xArm6 with gripper will appear and animate — rotating through 0° / 90° / 180° / -90° while opening and closing the gripper.

> **Note:** The Mesh "up" axis must be set to **Y-up** for the UFACTORY STL meshes to render correctly. Z-up causes the links to appear disconnected.

---

## Static Pose (No Animation)

To display the arm in a fixed hold-up pose without animation:

```bash
# Replace Terminal 4 with:
docker exec -it ros2_dev bash -c "
  source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash &&
  ros2 run xarm_description joint_state_pub"
```

---

## macOS CLI (Optional)

Inspect topics from macOS using the Zenoh bridge:

```bash
# Terminal — start Zenoh bridge first
./scripts/start_bridge.sh

# Then use the ros2 wrapper
./scripts/ros2.sh topic list
./scripts/ros2.sh topic echo /joint_states
./scripts/ros2.sh node list
```

---

## Stop Everything

```bash
# Ctrl+C in each terminal to stop individual nodes
docker compose down
```

---

## Known Issues and Fixes

| Issue | Fix |
|---|---|
| Container bridge IP unreachable from macOS | Zenoh bridge over TCP port 7447 |
| Homebrew Python 3.14 breaks rclpy imports | `scripts/ros2.sh` unsets `PYTHONPATH`, uses conda Python directly |
| `ros2 topic list` hangs 60 s | `--no-daemon` injected by wrapper |
| URDF links appear disconnected in Foxglove | Set **Scene → Mesh "up" axis → Y-up** in the 3D panel |
| CycloneDDS interface mismatch on macOS | `CYCLONEDDS_URI` config; `ROS_LOCALHOST_ONLY=1` on bridge |

---

## Roadmap

- [x] ROS2 Docker infrastructure (Zenoh bridge, Foxglove WebSocket)
- [x] xArm6 URDF + gripper meshes integrated as ROS2 packages
- [x] Robot model visualized and animated in Foxglove
- [x] Gripper open/close animation working
- [ ] Orbbec Astra camera integration (SDK + ROS2 driver)
- [ ] Point cloud processing (PCL — plane removal, clustering, 3D bounding box)
- [ ] Camera-to-robot TF2 calibration
- [ ] Conveyor state estimator (position tracking)
- [ ] Task scheduler with deadline-based queue
- [ ] MoveIt2 setup for xArm6 (IK, collision checking)
- [ ] Pick planner (antipodal grasp, yaw alignment)
- [ ] Container tracker + index controller
- [ ] Foxglove simulation (conveyor_sim, camera_sim, container_sim)
- [ ] Full end-to-end pick-and-place demo

---

## License

MIT
