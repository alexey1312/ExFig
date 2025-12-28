#!/bin/bash
# =============================================================================
# create-dmg.sh - Create DMG for ExFig Studio
# =============================================================================
# Creates a DMG installer for ExFig Studio with:
# - Custom background image (if provided)
# - App icon and Applications symlink
# - Proper volume name and icon
#
# Usage:
#   ./Scripts/create-dmg.sh <app-path> <output-dmg> [version]
#
# Example:
#   ./Scripts/create-dmg.sh dist/ExFig\ Studio.app dist/ExFigStudio-1.2.0.dmg 1.2.0
# =============================================================================

set -euo pipefail

APP_PATH="${1:-}"
OUTPUT_DMG="${2:-}"
VERSION="${3:-1.0.0}"

if [[ -z "$APP_PATH" || -z "$OUTPUT_DMG" ]]; then
    echo "Usage: $0 <app-path> <output-dmg> [version]"
    exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

VOLUME_NAME="ExFig Studio ${VERSION}"
STAGING_DIR=$(mktemp -d)
DMG_TEMP="${OUTPUT_DMG%.dmg}-temp.dmg"

cleanup() {
    rm -rf "$STAGING_DIR"
    rm -f "$DMG_TEMP"
}
trap cleanup EXIT

echo "Creating DMG for ExFig Studio ${VERSION}..."

# Create staging directory with app and symlink
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Calculate size (app size + 10MB buffer)
SIZE=$(du -sm "$STAGING_DIR" | cut -f1)
SIZE=$((SIZE + 10))

# Create temporary DMG
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size "${SIZE}m" \
    "$DMG_TEMP"

# Mount temporary DMG
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | grep "^/dev/" | head -1 | cut -f1)
MOUNT_POINT="/Volumes/$VOLUME_NAME"

# Wait for mount
sleep 2

# Set custom icon positions using AppleScript
osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 100, 1000, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100

        -- Position icons
        set position of item "ExFig Studio.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}

        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Sync and unmount
sync
hdiutil detach "$DEVICE"

# Convert to compressed read-only DMG
rm -f "$OUTPUT_DMG"
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$OUTPUT_DMG"

echo "DMG created: $OUTPUT_DMG"

# Calculate and display checksum
SHA256=$(shasum -a 256 "$OUTPUT_DMG" | cut -d' ' -f1)
echo "SHA256: $SHA256"
