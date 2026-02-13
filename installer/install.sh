#!/bin/bash
# Agent Skills Installer - Entry Point
# Supports CLI (terminal) and Web (browser) modes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"

show_help() {
    echo "Agent Skills Installer"
    echo ""
    echo "Usage:"
    echo "  ./install.sh              Interactive mode"
    echo "  ./install.sh --web        Web UI (opens browser)"
    echo "  ./install.sh <skill>      Install a skill"
    echo ""
    echo "Actions:"
    echo "  install     Install and configure"
    echo "  connect     Configure credentials"
    echo "  test        Test connection"
    echo "  uninstall   Remove skill"
    echo ""
    echo "Examples:"
    echo "  ./install.sh sentry"
    echo "  ./install.sh sentry test"
    echo "  ./install.sh --web"
}

# Parse arguments
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    --web|-w)
        # Check for Python
        if ! command -v python3 &> /dev/null; then
            echo "Error: Python 3 is required for web mode"
            echo "Install Python 3 or use CLI mode: ./install.sh"
            exit 1
        fi

        PORT="${2:-8765}"
        echo "Starting web installer..."
        echo "Press Ctrl+C to stop"
        echo ""

        python3 "$SCRIPT_DIR/web.py" "$PORT"
        ;;
    "")
        # Interactive CLI mode
        exec "$SCRIPT_DIR/cli.sh"
        ;;
    *)
        # Skill name provided
        SKILL="$1"
        ACTION="${2:-install}"
        exec "$SCRIPT_DIR/cli.sh" "$SKILL" "$ACTION"
        ;;
esac
