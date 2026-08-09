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
if [ ! -d "$APP_SOURCE" ] && [ ! -d "$PROJECT_DIR/$APP_NAME" ]; then
    echo "--> Building release app..."
    "$SCRIPT_DIR/build-app.sh"
fi

if [ -d "$PROJECT_DIR/$APP_NAME" ]; then
    APP_SOURCE="$PROJECT_DIR/$APP_NAME"
fi

# Clean DMG staging & previous archives
rm -rf "$DMG_STAGING_DIR" "$RELEASES_DIR/$DMG_FILENAME" "$RELEASES_DIR/$ZIP_FILENAME" "${DMG_OUT_BASE}.dmg"
mkdir -p "$DMG_STAGING_DIR" "$RELEASES_DIR"

# Copy App and create Applications symlink inside staging folder
echo "--> Staging archive contents..."
cp -R "$APP_SOURCE" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

# 1. Ensure app is ad-hoc signed and verified before packaging
echo "--> Cleaning extended attributes & applying ad-hoc code signature..."
xattr -cr "$DMG_STAGING_DIR/$APP_NAME"
codesign --force --deep --sign - "$DMG_STAGING_DIR/$APP_NAME"
codesign --verify --deep --strict --verbose=4 "$DMG_STAGING_DIR/$APP_NAME"

# 2. Create distribution ZIP archive using ditto
echo "--> Creating compressed release ZIP archive..."
ditto -c -k --sequesterRsrc "$APP_SOURCE" "$RELEASES_DIR/$ZIP_FILENAME"

# 3. Create compressed DMG archive using hybrid + convert pipeline
echo "--> Creating compressed DMG archive..."
TEMP_HYBRID="$BUILD_ROOT/temp_hybrid.dmg"
rm -f "$TEMP_HYBRID" "$TEMP_HYBRID.iso" "$RELEASES_DIR/$DMG_FILENAME"

hdiutil makehybrid -hfs -iso -joliet -o "$TEMP_HYBRID" "$DMG_STAGING_DIR"
hdiutil convert "$TEMP_HYBRID.iso" -format UDZO -o "$RELEASES_DIR/$DMG_FILENAME"
rm -f "$TEMP_HYBRID.iso"

# Copy to website downloads directory
WEBSITE_DOWNLOADS="$PROJECT_DIR/website/downloads"
mkdir -p "$WEBSITE_DOWNLOADS"
cp "$RELEASES_DIR/$DMG_FILENAME" "$WEBSITE_DOWNLOADS/$DMG_FILENAME"

# Calculate SHA-256 checksums
echo "--> Generating SHA-256 checksums..."
cd "$RELEASES_DIR"
shasum -a 256 "$DMG_FILENAME" > "${DMG_FILENAME}.sha256"
shasum -a 256 "$ZIP_FILENAME" > "${ZIP_FILENAME}.sha256"
cd "$PROJECT_DIR"

rm -rf "$DMG_STAGING_DIR"

echo "============================================================"
echo "Release Package Created Successfully:"
echo "DMG Path:     $RELEASES_DIR/$DMG_FILENAME"
echo "Website Path: $WEBSITE_DOWNLOADS/$DMG_FILENAME"
echo "DMG SHA-256:  $(cat "$RELEASES_DIR/${DMG_FILENAME}.sha256")"
echo "============================================================"
