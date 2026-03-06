#!/bin/bash
set -euo pipefail

APP_NAME="LinkDispatch"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "Building $APP_NAME..."

# Clean previous build
rm -rf "$BUILD_DIR"

# Create app bundle structure
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy Info.plist
cp Resources/Info.plist "$CONTENTS/Info.plist"

# Compile all Swift sources into the executable
swiftc \
    -o "$MACOS_DIR/$APP_NAME" \
    -target arm64-apple-macosx13.0 \
    -sdk $(xcrun --show-sdk-path) \
    -framework AppKit \
    -framework CoreServices \
    -swift-version 5 \
    Sources/*.swift

echo "Build complete: $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install: cp -r $APP_BUNDLE /Applications/"
echo ""
echo "After installing, set LinkDispatch as your default browser:"
echo "  System Settings > Desktop & Dock > Default web browser > LinkDispatch"
