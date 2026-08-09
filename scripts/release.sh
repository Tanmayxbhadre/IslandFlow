#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# IslandFlow — Master Release Orchestration Script (Phase 15.1)
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

MARKETING_VERSION="1.0.0"
BUILD_NUMBER="1"
BUNDLE_ID="com.islandflow.app"
APP_NAME="IslandFlow.app"
DMG_NAME="IslandFlow-${MARKETING_VERSION}.dmg"
ZIP_NAME="IslandFlow-${MARKETING_VERSION}.zip"

RELEASES_DIR="$PROJECT_DIR/build/releases"
APP_PATH="$RELEASES_DIR/$APP_NAME"
DMG_PATH="$RELEASES_DIR/$DMG_NAME"
ZIP_PATH="$RELEASES_DIR/$ZIP_NAME"

SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"

# Step 1: Execute release build
"$SCRIPT_DIR/build-release.sh"

# Step 2: Execute DMG & ZIP build
"$SCRIPT_DIR/build-dmg.sh"

# Step 3: Developer ID & Gatekeeper Evaluation
HAS_DEV_ID=false
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
    HAS_DEV_ID=true
fi

SIGNING_STATUS="AD-HOC (Local build mode)"
DEV_ID_STATUS="NOT CONFIGURED"
NOTARIZATION_STATUS="NOT CONFIGURED"
GATEKEEPER_STATUS="LOCAL EXECUTION SUPPORTED"

if [ "$HAS_DEV_ID" = true ] && [ -n "$SIGNING_IDENTITY" ]; then
    DEV_ID_STATUS="CONFIGURED ($SIGNING_IDENTITY)"
    SIGNING_STATUS="Developer ID Application ($SIGNING_IDENTITY)"
    if spctl --assess --type execute --verbose "$APP_PATH" 2>/dev/null; then
        GATEKEEPER_STATUS="PASS"
    else
        GATEKEEPER_STATUS="REQUIRES NOTARIZATION / STAPLING"
    fi
fi

ZIP_CHECKSUM=""
if [ -f "${ZIP_PATH}.sha256" ]; then
    ZIP_CHECKSUM="$(cat "${ZIP_PATH}.sha256" | awk '{print $1}')"
fi

DMG_CHECKSUM=""
if [ -f "${DMG_PATH}.sha256" ]; then
    DMG_CHECKSUM="$(cat "${DMG_PATH}.sha256" | awk '{print $1}')"
fi

# Step 4: Summary Report
echo ""
echo "============================================================"
echo "         ISLANDFLOW LOCAL & PRIVATE RELEASE SUMMARY         "
echo "============================================================"
echo "App Name:        IslandFlow"
echo "Version:         ${MARKETING_VERSION}"
echo "Build Number:    ${BUILD_NUMBER}"
echo "Architecture:    arm64"
echo "Bundle ID:       ${BUNDLE_ID}"
echo "------------------------------------------------------------"
echo "Developer ID:    ${DEV_ID_STATUS}"
echo "Signing Method:  ${SIGNING_STATUS}"
echo "Notarization:    ${NOTARIZATION_STATUS}"
echo "Gatekeeper Note: ${GATEKEEPER_STATUS}"
echo "------------------------------------------------------------"
echo "App Bundle:      ${APP_PATH}"
if [ -f "$DMG_PATH" ]; then
    echo "DMG Package:     ${DMG_PATH}"
    echo "DMG SHA-256:     ${DMG_CHECKSUM}"
fi
echo "ZIP Archive:     ${ZIP_PATH}"
echo "ZIP SHA-256:     ${ZIP_CHECKSUM}"
echo "============================================================"
echo "[SUCCESS] IslandFlow local release package ready!"
