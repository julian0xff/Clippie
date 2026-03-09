#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building Clippy..."
xcodebuild -project Clippy.xcodeproj -scheme Clippy -destination 'platform=macOS,arch=arm64' build 2>&1 | tail -5

BUILD_DIR=$(find ~/Library/Developer/Xcode/DerivedData/Clippy-*/Build/Products/Debug/Clippy.app -maxdepth 0 2>/dev/null | head -1)
if [[ -z "$BUILD_DIR" ]]; then
    echo "Error: Build output not found"
    exit 1
fi

echo "Quitting Clippy..."
osascript -e 'quit app "Clippy"' 2>/dev/null || true
sleep 1

echo "Deploying to /Applications..."
rm -rf /Applications/Clippy.app
cp -R "$BUILD_DIR" /Applications/Clippy.app

echo "Launching Clippy..."
open /Applications/Clippy.app

echo "Done."
