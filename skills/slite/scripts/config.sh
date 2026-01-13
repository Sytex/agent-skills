#!/bin/bash
# Slite API Configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine config location
if [[ "$SCRIPT_DIR" == *".slite"* ]]; then
    CONFIG_FILE="$HOME/.slite/.env"
elif [[ "$SCRIPT_DIR" == *".claude/skills/slite"* ]]; then
    CONFIG_FILE="$HOME/.slite/.env"
else
    CONFIG_FILE="$HOME/.slite/.env"
fi

mkdir -p "$(dirname "$CONFIG_FILE")"

setup_api_key() {
    echo "Enter your Slite API key:"
    read -r api_key

    if [[ -z "$api_key" ]]; then
        echo "Error: API key cannot be empty"
        exit 1
    fi

    echo "SLITE_API_KEY=$api_key" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo "API key saved to $CONFIG_FILE"
}

get_api_key() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        echo "$SLITE_API_KEY"
        return 0
    fi
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
