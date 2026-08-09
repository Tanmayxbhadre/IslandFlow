#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# IslandFlow — Local & Production Release Build Script (Phase 15.1)
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

MARKETING_VERSION="1.0.0"
BUILD_NUMBER="1"
BUNDLE_ID="com.islandflow.app"
APP_NAME="IslandFlow.app"

BUILD_ROOT="$PROJECT_DIR/build"
RELEASES_DIR="$BUILD_ROOT/releases"
STAGING_DIR="$BUILD_ROOT/staging"

SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
NOTARIZE="${NOTARIZE:-0}"

echo "============================================================"
echo "ISLANDFLOW RELEASE BUILD v${MARKETING_VERSION} (Build ${BUILD_NUMBER})"
echo "============================================================"

# 1. Clean staging & releases directories
rm -rf "$STAGING_DIR" "$RELEASES_DIR/$APP_NAME"
mkdir -p "$STAGING_DIR" "$RELEASES_DIR" ".build/module-cache" ".build/tmp"

APP_PATH="$STAGING_DIR/$APP_NAME"
CONTENTS_DIR="$APP_PATH/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# 2. Compile release binary
echo "--> Compiling release binary (arm64 -O)..."
SDK_PATH="$(xcrun --show-sdk-path)"
TMPDIR="$PROJECT_DIR/.build/tmp" \
DARWIN_USER_TEMP_DIR="$PROJECT_DIR/.build/tmp" \
DARWIN_USER_CACHE_DIR="$PROJECT_DIR/.build/module-cache" \
swiftc -O \
    -module-cache-path "$PROJECT_DIR/.build/module-cache" \
    -Xcc -fmodules-cache-path="$PROJECT_DIR/.build/module-cache" \
    -sdk "$SDK_PATH" \
    -parse-as-library $(find Sources/IslandFlow -name "*.swift") \
    -o "$MACOS_DIR/IslandFlow"

# 3. Create Info.plist
cat << EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>IslandFlow</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>IslandFlow</string>
    <key>CFBundleDisplayName</key>
    <string>IslandFlow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${MARKETING_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

# 4. Copy resources if any exist
if [ -d "Resources" ]; then
    cp -R Resources/* "$RESOURCES_DIR/" 2>/dev/null || true
fi

# 5. Discover Signing Identities & Apply Signature
HAS_DEV_ID=false
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
    HAS_DEV_ID=true
fi

ENTITLEMENTS_FILE="$PROJECT_DIR/Resources/entitlements.plist"

if [ "$HAS_DEV_ID" = true ] && [ -n "$SIGNING_IDENTITY" ]; then
    echo "--> Code signing with Developer ID: $SIGNING_IDENTITY..."
    codesign --force --options runtime --deep --sign "$SIGNING_IDENTITY" --entitlements "$ENTITLEMENTS_FILE" "$APP_PATH"
    echo "--> Verifying Developer ID signature..."
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
    codesign -dv --verbose=4 "$APP_PATH"
else
    echo "--> Developer ID not configured — creating local/private release."
    echo "--> Applying local ad-hoc code signature..."
    codesign --deep --force --sign - "$APP_PATH"
    echo "--> Verifying ad-hoc code signature..."
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
    codesign -dv --verbose=4 "$APP_PATH"
fi

# 6. Notarization check (only if Developer ID configured)
if [ "$NOTARIZE" = "1" ] && [ "$HAS_DEV_ID" = true ] && [ -n "$SIGNING_IDENTITY" ]; then
    echo "--> Submitting to Apple Notary Service..."
    if [ -n "${KEYCHAIN_PROFILE:-}" ]; then
        xcrun notarytool submit "$APP_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait
        xcrun stapler staple "$APP_PATH"
    else
        echo "[WARNING] KEYCHAIN_PROFILE not specified. Skipping notarization."
    fi
else
    echo "--> Apple Notarization: NOT CONFIGURED (Local/Private build mode)."
fi

# 7. App Bundle Validation
echo "--> Validating App Bundle structure..."
test -f "$CONTENTS_DIR/Info.plist" || (echo "ERROR: Missing Info.plist" && exit 1)
test -x "$MACOS_DIR/IslandFlow" || (echo "ERROR: Missing executable" && exit 1)

# 8. Copy to final release destination
cp -R "$APP_PATH" "$RELEASES_DIR/"
cp -R "$APP_PATH" "$PROJECT_DIR/"

echo "--> Production .app created at: $RELEASES_DIR/$APP_NAME"
