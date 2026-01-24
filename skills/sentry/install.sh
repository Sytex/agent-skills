#!/bin/bash

INSTALL_DIR="$HOME/.claude/skills/sentry"

echo "Installing Sentry CLI..."

mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/sentry" "$INSTALL_DIR/sentry"
cp "$(dirname "$0")/config.sh" "$INSTALL_DIR/config.sh"
chmod +x "$INSTALL_DIR/sentry"
chmod +x "$INSTALL_DIR/config.sh"

echo ""
echo "Installation complete!"
echo "Location: $INSTALL_DIR"
echo ""
echo "NEXT STEP - Configure your credentials:"
echo "  $INSTALL_DIR/config.sh setup"
