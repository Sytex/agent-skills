#!/bin/bash
# Install Google Calendar skill

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.claude/skills/gcalendar"

echo "Installing Google Calendar skill..."

# Create directory
mkdir -p "$INSTALL_DIR"

# Copy files
cp "$SCRIPT_DIR/gcalendar" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/SKILL.md" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/gcalendar"

echo ""
echo "Installed to: $INSTALL_DIR"
echo ""
echo "Next steps:"
echo "1. Create OAuth credentials at https://console.cloud.google.com/apis/credentials"
echo "2. Enable Google Calendar API"
echo "3. Run: $INSTALL_DIR/gcalendar auth"
