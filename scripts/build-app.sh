#!/usr/bin/env bash
set -e

# Package script to build and produce IslandFlow.app
echo "Building IslandFlow Release executable..."
swift build -c release

BUILD_PATH=".build/release/IslandFlow"
APP_DIR="IslandFlow.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Packaging into $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BUILD_PATH" "$MACOS_DIR/IslandFlow"

cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>IslandFlow</string>
    <key>CFBundleIdentifier</key>
    <string>com.islandflow.app</string>
    <key>CFBundleName</key>
    <string>IslandFlow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "IslandFlow.app created successfully!"
