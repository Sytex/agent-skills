#!/bin/bash
# Sytex API Configuration

CONFIG_DIR="$HOME/.claude/skills/sytex"
CONFIG_FILE="$CONFIG_DIR/.env"

mkdir -p "$CONFIG_DIR"

setup() {
    echo "=== Sytex API Configuration ==="
    echo ""

    echo "Enter your Sytex API Token:"
    read -r token
    [[ -z "$token" ]] && echo "Error: Token cannot be empty" && exit 1

    echo "Enter your Organization ID:"
    read -r org_id
    [[ -z "$org_id" ]] && echo "Error: Organization ID cannot be empty" && exit 1

    echo "Enter the API base URL (default: https://app.sytex.io):"
    read -r base_url
    [[ -z "$base_url" ]] && base_url="https://app.sytex.io"

    cat > "$CONFIG_FILE" << EOF
SYTEX_TOKEN=$token
SYTEX_ORG_ID=$org_id
SYTEX_BASE_URL=$base_url
EOF

    chmod 600 "$CONFIG_FILE"
    echo ""
    echo "Configuration saved to $CONFIG_FILE"
}

show() {
    [[ ! -f "$CONFIG_FILE" ]] && echo "Not configured. Run: config.sh setup" && exit 1

    source "$CONFIG_FILE"
    echo "Token: ${SYTEX_TOKEN:0:10}..."
    echo "Organization: $SYTEX_ORG_ID"
    echo "Base URL: $SYTEX_BASE_URL"
}

org() {
    [[ ! -f "$CONFIG_FILE" ]] && echo "Not configured. Run: config.sh setup" && exit 1

    source "$CONFIG_FILE"

    local new_org="$1"
    [[ -z "$new_org" ]] && echo "Organization: $SYTEX_ORG_ID" && exit 0

    sed -i '' "s/^SYTEX_ORG_ID=.*/SYTEX_ORG_ID=$new_org/" "$CONFIG_FILE"
    echo "Organization changed: $SYTEX_ORG_ID -> $new_org"
}

case "$1" in
    setup) setup ;;
    show) show ;;
    org) org "$2" ;;
    *)
        echo "Usage: $0 {setup|show|org [id]}"
        exit 1
        ;;
esac
