#!/usr/bin/env bash
# Build the web server into a standalone binary using PyInstaller
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DESKTOP_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$(dirname "$DESKTOP_DIR")"
INSTALLER_DIR="$REPO_DIR/installer"
OUT_DIR="$DESKTOP_DIR/bin"

mkdir -p "$OUT_DIR"

pyinstaller \
  --onedir \
  --name agent-skills-server \
  --distpath "$OUT_DIR" \
  --workpath "/tmp/pyinstaller-build" \
  --specpath "/tmp/pyinstaller-build" \
  --add-data "$INSTALLER_DIR/templates:templates" \
  --add-data "$INSTALLER_DIR/providers.json:." \
  --add-data "$INSTALLER_DIR/oauth.py:." \
  --noconfirm \
  --clean \
  "$INSTALLER_DIR/web.py"

echo "Built: $OUT_DIR/agent-skills-server/"
