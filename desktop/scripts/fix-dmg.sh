#!/usr/bin/env bash
# Fix DMG: hide .VolumeIcon.icns and remove .fseventsd
set -euo pipefail

DMG_DIR="src-tauri/target/release/bundle/dmg"
DMG=$(ls "$DMG_DIR"/*.dmg 2>/dev/null | head -1)

if [[ -z "$DMG" ]]; then
  echo "No DMG found in $DMG_DIR"
  exit 1
fi

echo "Fixing $DMG..."

RW_DMG="/tmp/agent-skills-rw-$$.dmg"
hdiutil convert "$DMG" -format UDRW -o "$RW_DMG" -quiet

MOUNT_OUTPUT=$(hdiutil attach "$RW_DMG" -nobrowse -noautoopen 2>&1)
MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | grep -oE '/Volumes/.*' | head -1)

echo "Mounted at: $MOUNT_DIR"

# Remove volume icon (cosmetic file that Finder shows despite hidden flags)
rm -f "$MOUNT_DIR/.VolumeIcon.icns" 2>/dev/null || true

# Remove fseventsd
rm -rf "$MOUNT_DIR/.fseventsd" 2>/dev/null || true

# Remove stale .DS_Store so Finder builds a fresh one
rm -f "$MOUNT_DIR/.DS_Store" 2>/dev/null || true

hdiutil detach "$MOUNT_DIR" -quiet
rm "$DMG"
hdiutil convert "$RW_DMG" -format UDZO -o "$DMG" -quiet
rm "$RW_DMG"

echo "Done: $DMG"
