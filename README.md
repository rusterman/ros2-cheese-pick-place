# ROS2 Dev Environment — macOS + Docker

Minimal ROS2 Humble setup: nodes run in Docker, RViz2 and the `ros2` CLI run natively on macOS.

## Architecture

```
macOS
├── RViz2 / ros2 CLI          (RoboStack conda env)
├── zenoh-bridge (client)     (bin/zenoh-bridge-ros2dds)
│       │
│       └── TCP localhost:7447  ← Docker port-forward
│
Docker container: ros2_dev
├── zenoh-bridge (router)     (port 7447)
├── ROS2 nodes                (FastDDS, domain 42)
│   ├── publisher
│   ├── subscriber
│   └── marker_publisher
└── /ros2_ws/src/hello_ros2
```

**Why Zenoh?** Docker Desktop on macOS runs containers inside a Linux VM. The container's bridge IP is unreachable from macOS, so raw DDS multicast/unicast peers don't work. Zenoh bridges ROS2 topics over TCP — which Docker port-forwarding does support.

**Why the `scripts/ros2.sh` wrapper?** Homebrew Python (3.14+) leaks into PATH and breaks rclpy's C extension loading when the RoboStack conda env is active. The wrapper unsets `PYTHONPATH` and uses the conda env's Python directly.

---

## Prerequisites

- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/) running
- [Miniforge](https://github.com/conda-forge/miniforge) with a `ros2` conda environment (RoboStack, ROS2 Humble)

---

## First-time setup

```bash
# 1. Download the macOS Zenoh bridge binary (gitignored, run once)
./scripts/download_zenoh.sh
```

---

## Build

```bash
# Build the Docker image
docker compose build

# Build the ROS2 workspace inside the container (run once, or after code changes)
docker compose up -d
docker exec ros2_dev bash -c "
  source /opt/ros/humble/setup.bash &&
  cd /ros2_ws &&
  colcon build --symlink-install"
```

---

## Run

**Step 1 — Start the container**

```bash
docker compose up -d
```

**Step 2 — Start the Zenoh bridge** (keep this terminal open)

Starts the router inside Docker **and** the client on macOS in one command:

```bash
./scripts/start_bridge.sh
```

You should see `[1/2] Starting Zenoh router...` then `[2/2] Starting Zenoh client...` — leave it running.

**Step 3 — Run nodes inside Docker** (each in its own terminal)

```bash
# Publisher — sends "Hello ROS2 #N" every second
docker exec -it ros2_dev bash -c "
  source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash &&
  ros2 run hello_ros2 publisher"

# Subscriber — prints received messages
docker exec -it ros2_dev bash -c "
  source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash &&
  ros2 run hello_ros2 subscriber"

# Marker publisher — publishes a green cube Marker to /visualization_marker
docker exec -it ros2_dev bash -c "
  source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash &&
  ros2 run hello_ros2 marker_publisher"
```

**Step 4 — Inspect topics from macOS**

```bash
./scripts/ros2.sh topic list                          # prints topic names and exits
./scripts/ros2.sh topic echo /hello_topic             # streams messages — Ctrl+C to stop
./scripts/ros2.sh topic echo /visualization_marker    # streams messages — Ctrl+C to stop
./scripts/ros2.sh topic hz /hello_topic               # streams rate — Ctrl+C to stop
./scripts/ros2.sh node list                           # prints node names and exits
```

> `topic echo` and `topic hz` stream continuously and show nothing until the first message arrives (~1 s). If they print `WARNING: Zenoh bridge is not running` the bridge from Step 2 is not active.

**Step 5 — Open RViz2** (with bridge running)

```bash
./scripts/rviz2.sh
```

In RViz2: set **Fixed Frame** to `map`, add **Marker** display on topic `/visualization_marker`.


---

## Logs and outputs

| What | Command |
|---|---|
| Live node output (foreground) | `docker exec -it ros2_dev bash -c "source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash && ros2 run hello_ros2 publisher"` — output prints in this terminal, Ctrl+C stops the node |
| Node log (background start) | Start with `docker exec -d ros2_dev bash -c "... exec ros2 run hello_ros2 publisher > /tmp/publisher.log 2>&1"`, then tail with `docker exec ros2_dev tail -f /tmp/publisher.log`. Step 3 uses foreground — `/tmp` files only exist for background-started nodes. |
| All running nodes | `docker exec ros2_dev bash -c "ps aux \| grep python3"` |
| Topic stream from macOS | `./scripts/ros2.sh topic echo /hello_topic` — streams until Ctrl+C |
| Publish rate from macOS | `./scripts/ros2.sh topic hz /hello_topic` — streams until Ctrl+C |
| Container stdout | `docker logs -f ros2_dev` (empty if CMD is bash — nodes started via exec don't write here) |

---

## Stop

```bash
# Stop all nodes: Ctrl+C in each terminal running docker exec -it
# Stop bridge: Ctrl+C in the start_bridge.sh terminal
# Stop container:
docker compose down
```

---

## Project structure

```
.
├── Dockerfile                  # ros:humble + colcon + zenoh-bridge
├── docker-compose.yml          # container definition, port 7447
├── src/
│   └── hello_ros2/
│       ├── hello_ros2/
│       │   ├── publisher.py        # publishes std_msgs/String at 1 Hz
│       │   ├── subscriber.py       # subscribes and prints
│       │   └── marker_publisher.py # publishes visualization_msgs/Marker
│       ├── package.xml
│       └── setup.py
├── config/
│   └── cyclonedds_macos.xml    # CycloneDDS config for macOS (loopback, AllowMulticast=spdp)
├── bin/
│   └── zenoh-bridge-ros2dds    # macOS binary (gitignored, download_zenoh.sh)
└── scripts/
    ├── download_zenoh.sh       # downloads bin/zenoh-bridge-ros2dds
    ├── start_bridge.sh         # starts Docker router + macOS Zenoh client bridge
    ├── ros2.sh                 # ros2 CLI wrapper with correct env vars
    └── rviz2.sh                # RViz2 launcher (sets AMENT_PREFIX_PATH and DDS config)
```

---

## Known issues and fixes applied

| Issue | Fix |
|---|---|
| Container bridge IP unreachable from macOS | Zenoh bridge over TCP port 7447 instead of raw DDS peers |
| Homebrew Python 3.14 breaks rclpy imports | `scripts/ros2.sh` unsets `PYTHONPATH`, uses conda env Python directly |
| `ros2 topic list` hangs 60 s | `--no-daemon` injected by `scripts/ros2.sh` for verbs that use the daemon |
| `ros2 topic hz` rejected `--no-daemon` | Wrapper now applies `--no-daemon` only to verbs that support it (list/echo/info/…), not streaming verbs (hz/bw/delay) |
| CycloneDDS `<Interfaces>` + `ROS_LOCALHOST_ONLY` conflict | `cyclonedds_macos.xml` handles interface selection via `CYCLONEDDS_URI`; `ROS_LOCALHOST_ONLY` not used |
| Missing Docker zenoh router step | `start_bridge.sh` now starts the Docker router first, then the macOS client |
| `ros_discovery_info` GID parse errors | `ROS_DISTRO=humble` set in bridge startup scripts |
| Message triplication on macOS loopback | `cyclonedds_macos.xml` sets `AllowMulticast=spdp` — discovery uses multicast, data uses unicast — eliminating the 3× delivery via IPv4/IPv6/multicast paths. |
