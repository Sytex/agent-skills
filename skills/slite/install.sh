#!/bin/bash
# Slite CLI Installer - Works with any AI agent

INSTALL_DIR="$HOME/.claude/skills/slite"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Slite CLI..."

mkdir -p "$INSTALL_DIR"

cp "$SCRIPT_DIR/scripts/config.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/slite" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/SKILL.md" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/"*

echo ""
echo "Installation complete!"
echo "Location: $INSTALL_DIR"
echo ""
echo "NEXT STEP - Configure your API key:"
echo "  $INSTALL_DIR/config.sh setup"
