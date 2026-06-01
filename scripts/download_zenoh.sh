#!/bin/bash
# Downloads the macOS Zenoh bridge binary into bin/.
# Run once after cloning the repo.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"
VERSION="1.9.0"
ARCH=$(uname -m)  # arm64 or x86_64

case "$ARCH" in
  arm64)   TARGET="aarch64-apple-darwin" ;;
  x86_64)  TARGET="x86_64-apple-darwin" ;;
  *)       echo "Unknown arch: $ARCH"; exit 1 ;;
esac

URL="https://github.com/eclipse-zenoh/zenoh-plugin-ros2dds/releases/download/${VERSION}/zenoh-plugin-ros2dds-${VERSION}-${TARGET}-standalone.zip"
ZIP="/tmp/zenoh-bridge-ros2dds.zip"

echo "Downloading zenoh-bridge-ros2dds v${VERSION} for ${TARGET}..."
curl -L "$URL" -o "$ZIP"
mkdir -p "$BIN_DIR"
unzip -o "$ZIP" zenoh-bridge-ros2dds -d "$BIN_DIR"
chmod +x "$BIN_DIR/zenoh-bridge-ros2dds"
rm "$ZIP"

echo "Done: $BIN_DIR/zenoh-bridge-ros2dds"
