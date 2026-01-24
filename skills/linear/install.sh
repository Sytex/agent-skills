#!/bin/bash

INSTALL_DIR="$HOME/.claude/skills/linear"

echo "Installing Linear CLI..."

mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/linear" "$INSTALL_DIR/linear"
cp "$(dirname "$0")/config.sh" "$INSTALL_DIR/config.sh"
chmod +x "$INSTALL_DIR/linear"
chmod +x "$INSTALL_DIR/config.sh"

echo ""
echo "Installation complete!"
echo "Location: $INSTALL_DIR"
echo ""
echo "NEXT STEP - Configure your credentials:"
echo "  $INSTALL_DIR/config.sh setup"
