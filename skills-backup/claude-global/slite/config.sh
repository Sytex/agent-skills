#!/bin/bash
# Slite API Configuration

CONFIG_DIR="$HOME/.claude/skills/slite"
CONFIG_FILE="$CONFIG_DIR/.env"

mkdir -p "$CONFIG_DIR"

setup_api_key() {
    echo "Enter your Slite API key:"
    read -r api_key

    [[ -z "$api_key" ]] && echo "Error: API key cannot be empty" && exit 1

    echo "SLITE_API_KEY=$api_key" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo "API key saved to $CONFIG_FILE"
}

get_api_key() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" && echo "$SLITE_API_KEY" && return 0
    echo ""
    return 1
}

case "$1" in
    setup)
        setup_api_key
        ;;
    get)
        get_api_key
        ;;
    *)
        echo "Usage: $0 {setup|get}"
        exit 1
        ;;
esac
