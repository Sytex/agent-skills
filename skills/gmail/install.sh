#!/bin/bash
# Gmail CLI Installer - Works with any AI agent

INSTALL_DIR="$HOME/.claude/skills/gmail"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Gmail CLI..."

mkdir -p "$INSTALL_DIR"

cp "$SCRIPT_DIR/scripts/config.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/scripts/api.sh" "$INSTALL_DIR/gmail"
cp "$SCRIPT_DIR/SKILL.md" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/"*.sh
chmod +x "$INSTALL_DIR/gmail"

echo ""
echo "Installation complete!"
echo "Location: $INSTALL_DIR"
echo ""
echo "SETUP:"
echo ""
echo "1. Create an App Password:"
echo "   https://myaccount.google.com/apppasswords"
echo "   (Requires 2FA enabled on your Google account)"
echo ""
echo "2. Configure:"
echo "   $INSTALL_DIR/config.sh setup"
echo ""
echo "3. Test:"
echo "   $INSTALL_DIR/gmail me"
