#!/bin/bash
# Sytex API Configuration - Token only

CONFIG_DIR="$HOME/.claude/skills/sytex"
CONFIG_FILE="$CONFIG_DIR/.env"

mkdir -p "$CONFIG_DIR"

setup() {
    echo "=== Sytex API Configuration ==="
    echo ""
    echo "Enter your Sytex API Token:"
    read -r token
    [[ -z "$token" ]] && echo "Error: Token cannot be empty" && exit 1

    cat > "$CONFIG_FILE" << EOF
SYTEX_TOKEN=$token
EOF

    chmod 600 "$CONFIG_FILE"
    echo ""
    echo "Configuration saved to $CONFIG_FILE"
    echo ""
    echo "Use --base-url and --org flags on every command."
}

show() {
    [[ ! -f "$CONFIG_FILE" ]] && echo "Not configured. Run: config.sh setup" && exit 1

    source "$CONFIG_FILE"
    echo "Token: ${SYTEX_TOKEN:0:10}..."
    echo ""
    echo "No defaults. Use --base-url and --org on every command."
    echo "Use 'find-org <name>' to discover org IDs across instances."
}

case "$1" in
    setup) setup ;;
    show) show ;;
    *)
        echo "Usage: $0 {setup|show}"
        exit 1
        ;;
esac
