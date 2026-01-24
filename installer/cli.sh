#!/bin/bash
# Agent Skills Installer - CLI Logic
# Uses gum for premium UX, falls back to simple bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"
BIN_DIR="$SCRIPT_DIR/bin"
GUM_VERSION="0.14.5"

# Colors for fallback mode
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Check if gum is available
GUM=""
init_gum() {
    # Check system gum first
    if command -v gum &> /dev/null; then
        GUM="gum"
        return 0
    fi

    # Check local bin
    if [[ -x "$BIN_DIR/gum" ]]; then
        GUM="$BIN_DIR/gum"
        return 0
    fi

    return 1
}

# Download gum if user agrees
download_gum() {
    local os arch url

    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"

    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) return 1 ;;
    esac

    case "$os" in
        darwin) os="Darwin" ;;
        linux) os="Linux" ;;
        *) return 1 ;;
    esac

    url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${os}_${arch}.tar.gz"

    mkdir -p "$BIN_DIR"
    echo "Downloading gum..."

    if command -v curl &> /dev/null; then
        curl -sL "$url" | tar xz -C "$BIN_DIR" --strip-components=1 "*/gum" 2>/dev/null
    elif command -v wget &> /dev/null; then
        wget -qO- "$url" | tar xz -C "$BIN_DIR" --strip-components=1 "*/gum" 2>/dev/null
    else
        echo "Error: curl or wget required"
        return 1
    fi

    # Verify download succeeded
    if [[ ! -f "$BIN_DIR/gum" ]]; then
        echo "Error: Download failed"
        return 1
    fi

    chmod +x "$BIN_DIR/gum"
    GUM="$BIN_DIR/gum"
    return 0
}

# Prompt to install gum
prompt_gum_install() {
    echo ""
    echo -e "${CYAN}For a better experience, we can download 'gum' (a CLI tool).${NC}"
    echo -e "${DIM}It will be installed locally in this directory, not system-wide.${NC}"
    echo ""
    read -p "Download gum? [y/N] " response

    if [[ "$response" =~ ^[Yy] ]]; then
        download_gum && return 0
    fi

    return 1
}

# Initialize gum (optional, fallback to bash if not available)
if ! init_gum; then
    prompt_gum_install || GUM=""
fi

# ============================================================================
# UI Helpers
# ============================================================================

# Style text
style() {
    local color="$1"
    shift
    if [[ -n "$GUM" ]]; then
        "$GUM" style --foreground "$color" "$@"
    else
        case "$color" in
            1|red) echo -e "${RED}$*${NC}" ;;
            2|green) echo -e "${GREEN}$*${NC}" ;;
            3|yellow) echo -e "${YELLOW}$*${NC}" ;;
            4|blue) echo -e "${BLUE}$*${NC}" ;;
            6|cyan) echo -e "${CYAN}$*${NC}" ;;
            *) echo "$*" ;;
        esac
    fi
}

# Show header
header() {
    clear
    if [[ -n "$GUM" ]]; then
        "$GUM" style --bold --foreground 4 "$1"
    else
        echo -e "${BOLD}${BLUE}$1${NC}"
    fi
    echo ""
}

# Show info box
info_box() {
    if [[ -n "$GUM" ]]; then
        "$GUM" style --foreground 6 "$1"
    else
        echo -e "${CYAN}$1${NC}"
    fi
}

# Choose from list
choose() {
    local prompt="$1"
    shift
    local options=("$@")

    if [[ -n "$GUM" ]]; then
        "$GUM" choose --header "$prompt" "${options[@]}"
    else
        echo -e "${BOLD}$prompt${NC}" >&2
        echo "" >&2
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt" >&2
            ((i++))
        done
        echo "" >&2
        while true; do
            read -p "Select [1-${#options[@]}]: " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
                echo "${options[$((choice-1))]}"
                return 0
            fi
            echo "Invalid choice" >&2
        done
    fi
}

# Confirm action
confirm() {
    local prompt="$1"

    if [[ -n "$GUM" ]]; then
        "$GUM" confirm "$prompt" && return 0 || return 1
    else
        read -p "$prompt [y/N] " response
        [[ "$response" =~ ^[Yy] ]] && return 0 || return 1
    fi
}

# Input text
input_text() {
    local prompt="$1"
    local default="$2"
    local result

    if [[ -n "$GUM" ]]; then
        result=$("$GUM" input --placeholder "$prompt" --value "$default")
    else
        if [[ -n "$default" ]]; then
            read -p "$prompt [$default]: " result
            result="${result:-$default}"
        else
            read -p "$prompt: " result
        fi
    fi

    echo "$result"
}

# Input password
input_password() {
    local prompt="$1"
    local result

    if [[ -n "$GUM" ]]; then
        result=$("$GUM" input --placeholder "$prompt" --password)
    else
        read -sp "$prompt: " result
        echo "" >&2
    fi

    echo "$result"
}

# Spinner
spin() {
    local title="$1"
    shift

    if [[ -n "$GUM" ]]; then
        "$GUM" spin --title "$title" -- "$@"
    else
        echo -n "$title "
        "$@" > /dev/null 2>&1
        echo "done"
    fi
}

# ============================================================================
# Skill Functions
# ============================================================================

# Get list of available skills
get_skills() {
    for dir in "$SKILLS_DIR"/*/; do
        [[ -f "$dir/skill.json" ]] && basename "$dir"
    done
}

# Read skill.json field using Python (cross-platform)
read_json() {
    local file="$1"
    local field="$2"

    python3 -c "
import json
with open('$file') as f:
    data = json.load(f)
    value = data.get('$field', '')
    if isinstance(value, list):
        print('\n'.join(str(v) if not isinstance(v, dict) else json.dumps(v) for v in value))
    else:
        print(value)
"
}

# Get install path for a skill
get_install_path() {
    local skill="$1"
    local path
    path=$(read_json "$SKILLS_DIR/$skill/skill.json" "install_path")
    echo "${path/#\~/$HOME}"
}

# Get skill status
get_skill_status() {
    local skill="$1"
    local install_path
    install_path=$(get_install_path "$skill")

    if [[ ! -d "$install_path" ]]; then
        echo "not_installed"
    elif [[ ! -f "$install_path/.env" ]]; then
        echo "installed"
    else
        echo "configured"
    fi
}

# Show skill info
show_skill_info() {
    local skill="$1"
    local skill_json="$SKILLS_DIR/$skill/skill.json"

    local title description version install_path status
    title=$(read_json "$skill_json" "title")
    description=$(read_json "$skill_json" "description")
    version=$(read_json "$skill_json" "version")
    install_path=$(get_install_path "$skill")
    status=$(get_skill_status "$skill")

    header "$title"

    echo -e "${DIM}$description${NC}"
    echo ""
    echo -e "Version:  ${BOLD}$version${NC}"
    echo -e "Path:     ${DIM}$install_path${NC}"
    echo -n "Status:   "

    case "$status" in
        not_installed)
            style yellow "Not installed"
            ;;
        installed)
            style cyan "Installed (needs configuration)"
            ;;
        configured)
            style green "Configured"
            ;;
    esac
    echo ""
}

# Get available actions for a skill
get_actions() {
    local status="$1"

    case "$status" in
        not_installed)
            echo "Install"
            echo "Back"
            ;;
        installed)
            echo "Connect"
            echo "Uninstall"
            echo "Back"
            ;;
        configured)
            echo "Test"
            echo "Edit credentials"
            echo "Uninstall"
            echo "Back"
            ;;
    esac
}

# Install skill files
install_files() {
    local skill="$1"
    local skill_dir="$SKILLS_DIR/$skill"
    local skill_json="$skill_dir/skill.json"
    local install_path
    install_path=$(get_install_path "$skill")

    mkdir -p "$install_path"

    # Read files list and copy
    while IFS= read -r file_spec; do
        [[ -z "$file_spec" ]] && continue

        local src dst
        if [[ "$file_spec" == *":"* ]]; then
            src="${file_spec%%:*}"
            dst="${file_spec##*:}"
        else
            src="$file_spec"
            dst="$(basename "$file_spec")"
        fi

        if [[ -f "$skill_dir/$src" ]]; then
            cp "$skill_dir/$src" "$install_path/$dst"
            chmod +x "$install_path/$dst" 2>/dev/null || true
        fi
    done < <(read_json "$skill_json" "files")
}

# Configure skill credentials
configure_skill() {
    local skill="$1"
    local skill_json="$SKILLS_DIR/$skill/skill.json"
    local install_path
    install_path=$(get_install_path "$skill")

    local setup_instructions
    setup_instructions=$(read_json "$skill_json" "setup_instructions")

    # Show setup instructions
    if [[ -n "$setup_instructions" ]]; then
        info_box "$setup_instructions"
        echo ""
    fi

    # Collect field values
    local env_content=""
    local field_count
    field_count=$(python3 -c "import json; print(len(json.load(open('$skill_json')).get('fields', [])))")

    for ((i=0; i<field_count; i++)); do
        local field_json name label type required default help help_url env_var value
        field_json=$(python3 -c "import json; print(json.dumps(json.load(open('$skill_json'))['fields'][$i]))")

        name=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('name',''))")
        label=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('label',''))")
        type=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('type','text'))")
        required=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('required',False))")
        default=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('default',''))")
        help=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('help',''))")
        help_url=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('help_url',''))")
        env_var=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('env_var',''))")

        # Show field info
        local required_mark=""
        [[ "$required" == "True" ]] && required_mark=" ${RED}(required)${NC}"

        echo -e "${BOLD}$label${NC}$required_mark"
        if [[ -n "$help" ]]; then
            echo "$help" | while IFS= read -r line; do
                echo -e "  ${DIM}$line${NC}"
            done
        fi
        [[ -n "$help_url" ]] && echo -e "  ${CYAN}↳ $help_url${NC}"

        # Get existing value if reconfiguring
        local existing=""
        if [[ -f "$install_path/.env" ]]; then
            existing=$(grep "^$env_var=" "$install_path/.env" 2>/dev/null | cut -d= -f2- | tr -d '"' || true)
        fi

        # Input value
        if [[ "$type" == "password" ]]; then
            if [[ -n "$existing" ]]; then
                echo -e "  ${DIM}Current: ****configured****${NC}"
                if ! confirm "  Change value?"; then
                    value="$existing"
                else
                    value=$(input_password "  Enter value")
                fi
            else
                value=$(input_password "  Enter value")
            fi
        else
            value=$(input_text "  Enter value" "${existing:-$default}")
        fi

        # Validate required
        if [[ "$required" == "True" ]] && [[ -z "$value" ]]; then
            style red "Error: $label is required"
            return 1
        fi

        env_content+="$env_var=\"$value\"\n"
        echo ""
    done

    # Write .env file
    echo -e "$env_content" > "$install_path/.env"
    chmod 600 "$install_path/.env"

    style green "Configuration saved to $install_path/.env"
}

# Test skill
test_skill() {
    local skill="$1"
    local skill_json="$SKILLS_DIR/$skill/skill.json"
    local install_path
    install_path=$(get_install_path "$skill")

    local test_cmd
    test_cmd=$(read_json "$skill_json" "test_command")

    if [[ -z "$test_cmd" ]]; then
        style yellow "No test command defined for this skill"
        return 1
    fi

    local executable="$install_path/$skill"
    if [[ ! -x "$executable" ]]; then
        style red "Executable not found: $executable"
        return 1
    fi

    echo "Running: $executable $test_cmd"
    echo ""

    if "$executable" $test_cmd; then
        echo ""
        style green "Test passed"
        return 0
    else
        echo ""
        style red "Test failed"
        return 1
    fi
}


# Uninstall skill
uninstall_skill() {
    local skill="$1"
    local install_path
    install_path=$(get_install_path "$skill")

    if [[ -d "$install_path" ]]; then
        rm -rf "$install_path"
        style green "Skill uninstalled"
    else
        style yellow "Skill not installed"
    fi
}

# ============================================================================
# Main Actions
# ============================================================================

do_install() {
    local skill="$1"

    style cyan "Installing $skill..."
    install_files "$skill"
    style green "Files installed"
    echo ""

    if confirm "Configure credentials now?"; then
        configure_skill "$skill"
    fi
}

do_configure() {
    local skill="$1"
    configure_skill "$skill"
}

do_test() {
    local skill="$1"
    test_skill "$skill"
}

do_uninstall() {
    local skill="$1"

    if confirm "Uninstall $skill? This will remove all files and credentials."; then
        uninstall_skill "$skill"
    fi
}

# ============================================================================
# Main Loop
# ============================================================================

main_menu() {
    while true; do
        header "Agent Skills Installer"

        # Build skill list with status
        local skills=()
        local skill_options=()
        while IFS= read -r skill; do
            skills+=("$skill")
            local status title
            status=$(get_skill_status "$skill")
            title=$(read_json "$SKILLS_DIR/$skill/skill.json" "title")

            local status_text
            case "$status" in
                not_installed) status_text="" ;;
                installed) status_text="(needs setup)" ;;
                configured) status_text="(ready)" ;;
            esac

            skill_options+=("$title $status_text")
        done < <(get_skills)

        skill_options+=("Exit")

        # Choose skill
        local choice
        choice=$(choose "Select a skill:" "${skill_options[@]}")

        [[ "$choice" == "Exit" ]] && break

        # Extract skill name from choice (remove status text in parentheses)
        local skill_title="${choice%% (*}"
        skill_title="${skill_title% }"  # trim trailing space
        local selected_skill=""
        for skill in "${skills[@]}"; do
            local title
            title=$(read_json "$SKILLS_DIR/$skill/skill.json" "title")
            if [[ "$title" == "$skill_title" ]]; then
                selected_skill="$skill"
                break
            fi
        done

        [[ -z "$selected_skill" ]] && continue

        skill_menu "$selected_skill"
    done
}

skill_menu() {
    local skill="$1"

    while true; do
        show_skill_info "$skill"

        local status
        status=$(get_skill_status "$skill")

        local actions=()
        while IFS= read -r action; do
            actions+=("$action")
        done < <(get_actions "$status")

        local action
        action=$(choose "Select action:" "${actions[@]}")

        case "$action" in
            "Install") do_install "$skill" ;;
            "Connect") do_configure "$skill" ;;
            "Test") do_test "$skill" ;;
            "Edit credentials") do_configure "$skill" ;;
            "Uninstall") do_uninstall "$skill" ;;
            "Back") break ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

# ============================================================================
# Entry Point
# ============================================================================

if [[ $# -eq 0 ]]; then
    main_menu
else
    skill="$1"
    action="${2:-install}"

    if [[ ! -d "$SKILLS_DIR/$skill" ]]; then
        style red "Error: Skill '$skill' not found"
        echo "Available skills:"
        get_skills | while read -r s; do echo "  - $s"; done
        exit 1
    fi

    show_skill_info "$skill"

    case "$action" in
        install) do_install "$skill" ;;
        connect) do_configure "$skill" ;;
        test) do_test "$skill" ;;
        uninstall) do_uninstall "$skill" ;;
        *)
            style red "Unknown action: $action"
            echo "Available: install, connect, test, uninstall"
            exit 1
            ;;
    esac
fi
