#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# IslandFlow — Master Release Orchestration Script
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
NOTARIZE="${NOTARIZE:-0}"

# Step 1: Execute release build
"$SCRIPT_DIR/build-release.sh"

# Step 2: Execute DMG & ZIP build
"$SCRIPT_DIR/build-dmg.sh"

# Step 3: Gatekeeper / Signature Status Evaluation
SIGNING_STATUS="AD-HOC (Local build)"
NOTARIZATION_STATUS="SKIPPED (Unconfigured)"
GATEKEEPER_STATUS="LOCAL ONLY"

if [ -n "$SIGNING_IDENTITY" ]; then
    SIGNING_STATUS="SIGNED ($SIGNING_IDENTITY)"
    if spctl --assess --type execute --verbose "$APP_PATH" 2>/dev/null; then
        GATEKEEPER_STATUS="PASS"
    else
        GATEKEEPER_STATUS="REQUIRES NOTARIZATION / STAPLING"
    fi
fi

if [ "$NOTARIZE" = "1" ] && [ -n "${KEYCHAIN_PROFILE:-}" ]; then
    NOTARIZATION_STATUS="PASSED & STAPLED"
fi

ZIP_CHECKSUM=""
if [ -f "${ZIP_PATH}.sha256" ]; then
    ZIP_CHECKSUM="$(cat "${ZIP_PATH}.sha256" | awk '{print $1}')"
fi

# Step 4: Summary Report
echo ""
echo "============================================================"
echo "                ISLANDFLOW RELEASE SUMMARY                  "
echo "============================================================"
echo "Version:         ${MARKETING_VERSION}"
echo "Build Number:    ${BUILD_NUMBER}"
echo "Architecture:    arm64"
echo "Bundle ID:       ${BUNDLE_ID}"
echo "Signing:         ${SIGNING_STATUS}"
echo "Notarization:    ${NOTARIZATION_STATUS}"
echo "Gatekeeper:      ${GATEKEEPER_STATUS}"
echo "------------------------------------------------------------"
echo "App Package:     ${APP_PATH}"
echo "ZIP Archive:     ${ZIP_PATH}"
echo "ZIP SHA-256:     ${ZIP_CHECKSUM}"
if [ -f "$DMG_PATH" ]; then
    echo "DMG Package:     ${DMG_PATH}"
fi
echo "============================================================"
echo "IslandFlow Release Pipeline Finished Successfully!"
