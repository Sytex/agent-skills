#!/bin/bash
# Gmail IMAP Configuration

CONFIG_DIR="$HOME/.claude/skills/gmail"
CONFIG_FILE="$CONFIG_DIR/.env"

mkdir -p "$CONFIG_DIR"

cmd_setup() {
    echo "Gmail IMAP Setup"
    echo "================"
    echo ""
    echo "You need an App Password from Google."
    echo ""
    echo "1. Go to: https://myaccount.google.com/apppasswords"
    echo "2. Select app: Mail"
    echo "3. Select device: Other (enter 'Gmail CLI')"
    echo "4. Click Generate"
    echo "5. Copy the 16-character password"
    echo ""
    echo "Note: Requires 2FA enabled on your Google account."
    echo ""

    echo "Enter your Gmail address:"
    read -r email

    [[ -z "$email" ]] && echo "Error: Email cannot be empty" && exit 1

    echo "Enter your App Password (16 characters, no spaces):"
    read -rs app_password

    [[ -z "$app_password" ]] && echo "Error: App Password cannot be empty" && exit 1

    echo "GMAIL_EMAIL=$email" > "$CONFIG_FILE"
    echo "GMAIL_APP_PASSWORD=$app_password" >> "$CONFIG_FILE"

    chmod 600 "$CONFIG_FILE"
    echo ""
    echo "Credentials saved to $CONFIG_FILE"
    echo ""
    echo "Test with: ~/.claude/skills/gmail/gmail me"
}

cmd_status() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Status: Not configured"
        echo ""
        echo "Run: ~/.claude/skills/gmail/config.sh setup"
        exit 0
    fi

    source "$CONFIG_FILE"
    echo "Gmail IMAP Status"
    echo "-----------------"
    echo "Email: $GMAIL_EMAIL"
    echo "App Password: ****configured****"
}

case "$1" in
    setup)
        cmd_setup
        ;;
    status)
        cmd_status
        ;;
    *)
        echo "Usage: $0 {setup|status}"
        exit 1
        ;;
esac
