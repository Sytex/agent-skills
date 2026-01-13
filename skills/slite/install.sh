#!/bin/bash
# Slite CLI Installer - Works with any AI agent (Claude, Codex, Cursor, etc.)

INSTALL_DIR="$HOME/.slite"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Slite CLI..."

# Create directory
mkdir -p "$INSTALL_DIR"

# Copy scripts
cp "$SCRIPT_DIR/scripts/config.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/scripts/api.sh" "$INSTALL_DIR/slite"

# Make executable
chmod +x "$INSTALL_DIR/"*

# Claude Code: install SKILL.md
if [[ -d "$HOME/.claude" ]]; then
    mkdir -p "$HOME/.claude/skills/slite"
    cp "$SCRIPT_DIR/SKILL.md" "$HOME/.claude/skills/slite/"
    ln -sf "$INSTALL_DIR/slite" "$HOME/.claude/skills/slite/slite"
    ln -sf "$INSTALL_DIR/config.sh" "$HOME/.claude/skills/slite/config.sh"
    ln -sf "$INSTALL_DIR/.env" "$HOME/.claude/skills/slite/.env" 2>/dev/null
    echo "Claude Code skill installed"
fi

echo ""
echo "Installation complete!"
echo "Location: $INSTALL_DIR"
echo ""
echo "NEXT STEP - Configure your API key:"
echo "  $INSTALL_DIR/config.sh setup"
echo ""
echo "Or tell your AI agent:"
echo '  "Run ~/.slite/config.sh setup and I will provide my API key"'
