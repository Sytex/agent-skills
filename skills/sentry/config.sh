#!/bin/bash

CONFIG_DIR="$HOME/.claude/skills/sentry"
CONFIG_FILE="$CONFIG_DIR/.env"

setup() {
    mkdir -p "$CONFIG_DIR"

    echo "Sentry API Configuration"
    echo "========================"
    echo ""
    echo "Get your token from: Settings > Auth Tokens"
    echo "Or create an Internal Integration for org-level access."
    echo ""

    read -p "Sentry Auth Token: " token
    read -p "Sentry Base URL [https://sentry.io]: " base_url
    base_url="${base_url:-https://sentry.io}"
    read -p "Default Organization slug: " org

    cat > "$CONFIG_FILE" << EOF
SENTRY_TOKEN="$token"
SENTRY_BASE_URL="$base_url"
SENTRY_ORG="$org"
EOF

    chmod 600 "$CONFIG_FILE"

    echo ""
    echo "Configuration saved to $CONFIG_FILE"
    echo ""
    echo "Test with: ~/.claude/skills/sentry/sentry projects"
}

show() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "Current configuration:"
        cat "$CONFIG_FILE" | sed 's/TOKEN=".*"/TOKEN="***"/'
    else
        echo "Not configured. Run: $0 setup"
    fi
}

case "$1" in
    setup) setup ;;
    show) show ;;
    *) echo "Usage: $0 {setup|show}" ;;
esac
