#!/usr/bin/env bash
# Post-build: inject server binary into .app, then rebuild a clean DMG
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DESKTOP_DIR="$(dirname "$SCRIPT_DIR")"
APP="$DESKTOP_DIR/src-tauri/target/release/bundle/macos/Agent Skills.app"
RESOURCES="$APP/Contents/Resources"
SERVER_DIR="$DESKTOP_DIR/bin/agent-skills-server"

# 1. Inject server into .app
if [[ ! -d "$SERVER_DIR" ]]; then
  echo "Server not found at $SERVER_DIR — run ./scripts/build-server.sh first"
  exit 1
fi

echo "Injecting server into .app..."
cp -R "$SERVER_DIR" "$RESOURCES/agent-skills-server"
chmod +x "$RESOURCES/agent-skills-server/agent-skills-server"

# 2. Rebuild DMG from the .app
echo "Creating DMG..."
DMG_DIR="$DESKTOP_DIR/src-tauri/target/release/bundle/dmg"
DMG="$DMG_DIR/Agent Skills_0.1.0_aarch64.dmg"
mkdir -p "$DMG_DIR"
rm -f "$DMG"

STAGING="/tmp/agent-skills-dmg-$$"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create "$DMG" \
  -volname "Agent Skills" \
  -srcfolder "$STAGING" \
  -format UDZO \
  -fs HFS+ \
  -quiet

rm -rf "$STAGING"
echo "Done: $DMG"
