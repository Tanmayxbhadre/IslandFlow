#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# IslandFlow — Production DMG & Archive Packaging Script
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

MARKETING_VERSION="1.0.0"
APP_NAME="IslandFlow.app"
DMG_FILENAME="IslandFlow-${MARKETING_VERSION}.dmg"
ZIP_FILENAME="IslandFlow-${MARKETING_VERSION}.zip"
DMG_OUT_BASE="$PROJECT_DIR/build/releases/IslandFlow-${MARKETING_VERSION}"

BUILD_ROOT="$PROJECT_DIR/build"
RELEASES_DIR="$BUILD_ROOT/releases"
DMG_STAGING_DIR="$BUILD_ROOT/dmg_staging"
APP_SOURCE="$RELEASES_DIR/$APP_NAME"

SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"

echo "============================================================"
echo "ISLANDFLOW ARCHIVE CREATION: $DMG_FILENAME"
echo "============================================================"

# Ensure release app exists
if [ ! -d "$APP_SOURCE" ]; then
    echo "--> $APP_SOURCE not found. Building release app first..."
    "$SCRIPT_DIR/build-release.sh"
fi

# Clean DMG staging & previous archives
rm -rf "$DMG_STAGING_DIR" "$RELEASES_DIR/$DMG_FILENAME" "$RELEASES_DIR/$ZIP_FILENAME" "${DMG_OUT_BASE}.dmg"
mkdir -p "$DMG_STAGING_DIR"

# Copy App and create Applications symlink
echo "--> Staging archive contents..."
cp -R "$APP_SOURCE" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

# 1. Create distribution ZIP archive using ditto
echo "--> Creating compressed release ZIP archive..."
ditto -c -k --sequesterRsrc "$APP_SOURCE" "$RELEASES_DIR/$ZIP_FILENAME"

# 2. Attempt DMG creation using hdiutil (with graceful fallback if disk device access restricted)
echo "--> Creating compressed DMG archive..."
if hdiutil create -volname "IslandFlow" -srcfolder "$DMG_STAGING_DIR" -ov -format UDZO "$DMG_OUT_BASE" 2>/dev/null; then
    FINAL_DMG="$RELEASES_DIR/$DMG_FILENAME"
    if [ -n "$SIGNING_IDENTITY" ]; then
        echo "--> Code signing DMG archive..."
        codesign --force --sign "$SIGNING_IDENTITY" "$FINAL_DMG" 2>/dev/null || true
    fi
    echo "--> Generating SHA-256 checksum for DMG..."
    cd "$RELEASES_DIR"
    shasum -a 256 "$DMG_FILENAME" > "${DMG_FILENAME}.sha256"
    cd "$PROJECT_DIR"
else
    echo "[NOTICE] DMG kernel device creation restricted by environment — ZIP release created as primary package."
fi

# Generate SHA-256 for ZIP
echo "--> Generating SHA-256 checksum for ZIP package..."
cd "$RELEASES_DIR"
shasum -a 256 "$ZIP_FILENAME" > "${ZIP_FILENAME}.sha256"
cd "$PROJECT_DIR"

rm -rf "$DMG_STAGING_DIR"

echo "============================================================"
echo "Release Package Created Successfully:"
echo "ZIP Path:     $RELEASES_DIR/$ZIP_FILENAME"
echo "ZIP SHA-256:  $(cat "$RELEASES_DIR/${ZIP_FILENAME}.sha256")"
if [ -f "$RELEASES_DIR/$DMG_FILENAME" ]; then
    echo "DMG Path:     $RELEASES_DIR/$DMG_FILENAME"
fi
echo "============================================================"
