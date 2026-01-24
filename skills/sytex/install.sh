#!/bin/bash
# Sytex CLI Installer

INSTALL_DIR="$HOME/.claude/skills/sytex"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Sytex CLI..."

mkdir -p "$INSTALL_DIR"

cp "$SCRIPT_DIR/scripts/config.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/sytex" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/SKILL.md" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/FORM_TEMPLATES.md" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/"*

echo ""
echo "Installation complete!"
echo "Location: $INSTALL_DIR"
echo ""
echo "NEXT STEP - Configure your credentials:"
echo "  $INSTALL_DIR/config.sh setup"
