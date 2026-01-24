#!/bin/bash

CONFIG_DIR="$HOME/.claude/skills/linear"
CONFIG_FILE="$CONFIG_DIR/.env"

setup() {
    mkdir -p "$CONFIG_DIR"

    echo "Linear API Configuration"
    echo "========================"
    echo ""
    echo "Get your API key from: Settings > Security & access > Personal API keys"
    echo ""

    read -p "Linear API Key: " token

    cat > "$CONFIG_FILE" << EOF
LINEAR_API_KEY="$token"
EOF

    chmod 600 "$CONFIG_FILE"

    echo ""
    echo "Configuration saved to $CONFIG_FILE"
    echo ""
    echo "Test with: ~/.claude/skills/linear/linear me"
}

show() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "Current configuration:"
        cat "$CONFIG_FILE" | sed 's/API_KEY=".*"/API_KEY="***"/'
    else
        echo "Not configured. Run: $0 setup"
    fi
}

case "$1" in
    setup) setup ;;
    show) show ;;
    *) echo "Usage: $0 {setup|show}" ;;
esac
