#!/bin/bash
# Agent Skills Installer - CLI Logic
# Uses gum for premium UX, falls back to simple bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"
BIN_DIR="$SCRIPT_DIR/bin"
GUM_VERSION="0.14.5"

# Provider configuration
CONFIG_DIR="$HOME/.agent-skills"
CONFIG_FILE="$CONFIG_DIR/config.json"
PROVIDERS_FILE="$SCRIPT_DIR/providers.json"

# Load default providers from providers.json
load_default_providers() {
    python3 -c "
import json
from pathlib import Path

providers_file = Path('$PROVIDERS_FILE')
if providers_file.exists():
    with open(providers_file) as f:
        for p in json.load(f):
            print(p['id'])
"
}

# Get all providers (defaults + custom from config)
get_all_providers() {
    init_config
    python3 -c "
import json
from pathlib import Path

# Load defaults
default_ids = set()
providers_file = Path('$PROVIDERS_FILE')
if providers_file.exists():
    with open(providers_file) as f:
        default_ids = {p['id'] for p in json.load(f)}

# Load config
config_file = Path('$CONFIG_FILE')
config_ids = set()
if config_file.exists():
    with open(config_file) as f:
        config = json.load(f)
        config_ids = set(config.get('providers', {}).keys())

# Combine: defaults first, then custom ones
all_ids = list(default_ids) + [p for p in config_ids if p not in default_ids]
for pid in all_ids:
    print(pid)
"
}

# Get provider name (from config or defaults)
get_provider_name() {
    local provider="$1"
    python3 -c "
import json
from pathlib import Path

provider = '$provider'

# Check config first (for custom providers)
config_file = Path('$CONFIG_FILE')
if config_file.exists():
    with open(config_file) as f:
        config = json.load(f)
        p_config = config.get('providers', {}).get(provider, {})
        if p_config.get('name'):
            print(p_config['name'])
            exit(0)

# Check defaults
providers_file = Path('$PROVIDERS_FILE')
if providers_file.exists():
    with open(providers_file) as f:
        for p in json.load(f):
            if p['id'] == provider:
                print(p['name'])
                exit(0)

# Fallback to ID
print(provider)
"
}

# Get provider default path (from config or defaults)
get_provider_default_path() {
    local provider="$1"
    python3 -c "
import json
from pathlib import Path

provider = '$provider'

# Check config first (for custom path or custom provider)
config_file = Path('$CONFIG_FILE')
if config_file.exists():
    with open(config_file) as f:
        config = json.load(f)
        p_config = config.get('providers', {}).get(provider, {})
        if p_config.get('path'):
            path = p_config['path']
            print(path.replace('~', str(Path.home())))
            exit(0)

# Check defaults
providers_file = Path('$PROVIDERS_FILE')
if providers_file.exists():
    with open(providers_file) as f:
        for p in json.load(f):
            if p['id'] == provider:
                path = p['path']
                print(path.replace('~', str(Path.home())))
                exit(0)

print('')
"
}

# Check if provider is custom (not in defaults)
is_custom_provider() {
    local provider="$1"
    python3 -c "
import json
from pathlib import Path

provider = '$provider'

providers_file = Path('$PROVIDERS_FILE')
if providers_file.exists():
    with open(providers_file) as f:
        for p in json.load(f):
            if p['id'] == provider:
                exit(1)  # Not custom (found in defaults)

exit(0)  # Custom (not found in defaults)
"
}

# Add a custom provider to config
add_custom_provider() {
    local provider_id="$1"
    local provider_name="$2"
    local provider_path="$3"

    init_config
    python3 -c "
import json
from pathlib import Path

config_file = Path('$CONFIG_FILE')
with open(config_file, 'r') as f:
    data = json.load(f)

if 'providers' not in data:
    data['providers'] = {}

data['providers']['$provider_id'] = {
    'enabled': True,
    'path': '$provider_path',
    'name': '$provider_name',
    'custom': True
}

with open(config_file, 'w') as f:
    json.dump(data, f, indent=2)
"
}

# Remove a custom provider from config
remove_custom_provider() {
    local provider="$1"

    init_config
    python3 -c "
import json
from pathlib import Path

config_file = Path('$CONFIG_FILE')
with open(config_file, 'r') as f:
    data = json.load(f)

data.get('providers', {}).pop('$provider', None)

with open(config_file, 'w') as f:
    json.dump(data, f, indent=2)
"
}

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

    local tmpfile="/tmp/gum_$$.tar.gz"

    if command -v curl &> /dev/null; then
        curl -sL "$url" -o "$tmpfile"
    elif command -v wget &> /dev/null; then
        wget -q "$url" -O "$tmpfile"
    else
        echo "Error: curl or wget required"
        return 1
    fi

    # Extract (try GNU tar first, then BSD tar)
    tar -xzf "$tmpfile" -C "$BIN_DIR" --wildcards --strip-components=1 "*/gum" 2>/dev/null || \
    tar -xzf "$tmpfile" -C "$BIN_DIR" --strip-components=1 "*/gum" 2>/dev/null

    rm -f "$tmpfile"

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
        local result
        result=$("$GUM" choose --header "$prompt" "${options[@]}") || { echo "Back"; return 0; }
        echo "$result"
    else
        echo -e "${BOLD}$prompt${NC}" >&2
        echo -e "${DIM}(q to go back)${NC}" >&2
        echo "" >&2
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt" >&2
            ((i++))
        done
        echo "" >&2
        while true; do
            read -p "Select [1-${#options[@]}]: " choice
            [[ "$choice" == "q" || "$choice" == "Q" || -z "$choice" ]] && { echo "Back"; return 0; }
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
        "$GUM" confirm --default=false "$prompt" && return 0 || return 1
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
        result=$("$GUM" input --placeholder "$prompt" --value="$default")
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
# Provider Functions
# ============================================================================

# Initialize config directory
init_config() {
    mkdir -p "$CONFIG_DIR"
    [[ -f "$CONFIG_FILE" ]] || echo '{"providers":{}}' > "$CONFIG_FILE"
}

# Get enabled providers as newline-separated list
get_enabled_providers() {
    init_config
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
for name, info in data.get('providers', {}).items():
    if info.get('enabled', False):
        print(name)
"
}

# Get provider path
get_provider_path() {
    local provider="$1"
    init_config
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
path = data.get('providers', {}).get('$provider', {}).get('path', '')
print(path)
"
}

# Check if any provider is enabled
has_enabled_providers() {
    local count
    count=$(get_enabled_providers | wc -l | tr -d ' ')
    [[ "$count" -gt 0 ]]
}

# Add or update a provider
set_provider() {
    local provider="$1"
    local enabled="$2"
    local path="$3"

    init_config
    local py_enabled="False"
    [[ "$enabled" == "true" ]] && py_enabled="True"
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
if 'providers' not in data:
    data['providers'] = {}
data['providers']['$provider'] = {'enabled': $py_enabled, 'path': '$path'}
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
}

# Remove a provider
remove_provider() {
    local provider="$1"

    init_config
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
data.get('providers', {}).pop('$provider', None)
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
}

# Get selected provider for viewing
get_selected_provider() {
    init_config
    local selected
    selected=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
print(data.get('selected_provider', ''))
")
    # If no selection or selection is not enabled, return first enabled
    if [[ -z "$selected" ]] || [[ -z "$(get_provider_path "$selected")" ]]; then
        selected=$(get_enabled_providers | head -1)
    fi
    echo "$selected"
}

# Set selected provider for viewing
set_selected_provider() {
    local provider="$1"
    init_config
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
data['selected_provider'] = '$provider'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
}

# Update skills from git repository
update_skills() {
    local repo_dir
    repo_dir=$(dirname "$SKILLS_DIR")

    echo "Pulling latest changes..."
    if git -C "$repo_dir" pull; then
        style green "Skills updated successfully"
    else
        style red "Failed to update skills"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

# Show provider management menu
manage_providers() {
    while true; do
        header "Manage Providers"

        echo -e "${DIM}Manage where skills can be installed.${NC}"
        echo ""

        # Show all providers (defaults + custom)
        echo "Default providers:"
        while IFS= read -r provider; do
            [[ -z "$provider" ]] && continue
            is_custom_provider "$provider" && continue
            local name="$(get_provider_name "$provider")"
            local path="$(get_provider_default_path "$provider")"
            echo -e "  ${CYAN}•${NC} $name"
            echo -e "    ${DIM}$path${NC}"
        done < <(get_all_providers)
        echo ""

        # Show custom providers
        local has_custom=false
        while IFS= read -r provider; do
            [[ -z "$provider" ]] && continue
            is_custom_provider "$provider" || continue
            has_custom=true
            local name="$(get_provider_name "$provider")"
            local path="$(get_provider_path "$provider")"
            echo -e "  ${GREEN}•${NC} $name ${CYAN}(custom)${NC}"
            echo -e "    ${DIM}$path${NC}"
        done < <(get_all_providers)

        if [[ "$has_custom" == "true" ]]; then
            echo ""
        fi

        # Build menu options: only custom providers can be removed
        local options=()
        while IFS= read -r provider; do
            [[ -z "$provider" ]] && continue
            is_custom_provider "$provider" || continue
            local name="$(get_provider_name "$provider")"
            options+=("Remove $name")
        done < <(get_all_providers)

        [[ ${#options[@]} -gt 0 ]] && options+=("─────────────")
        options+=("Add custom provider")
        options+=("Back")

        local action
        action=$(choose "Select action:" "${options[@]}")

        [[ "$action" == "Back" ]] && break
        [[ "$action" == "─────────────" ]] && continue

        if [[ "$action" == "Add custom provider" ]]; then
            echo ""
            local custom_id custom_path

            custom_id=$(input_text "Provider ID (e.g., cursor, windsurf)")
            [[ -z "$custom_id" ]] && continue

            # Normalize ID
            custom_id=$(echo "$custom_id" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

            # Validate ID doesn't already exist
            local existing_path
            existing_path=$(get_provider_path "$custom_id" 2>/dev/null)
            if [[ -n "$existing_path" ]]; then
                style red "Provider '$custom_id' already exists"
                read -p "Press Enter to continue..."
                continue
            fi

            custom_path=$(input_text "Install path" "$HOME/.$custom_id/skills")

            add_custom_provider "$custom_id" "$custom_id" "$custom_path"
            style green "Added custom provider: $custom_id"
        elif [[ "$action" == Remove* ]]; then
            # Extract provider name from action
            local action_name="${action#Remove }"
            # Find provider ID by name (only custom providers)
            while IFS= read -r provider; do
                is_custom_provider "$provider" || continue
                local name="$(get_provider_name "$provider")"
                if [[ "$name" == "$action_name" ]]; then
                    remove_custom_provider "$provider"
                    style yellow "Removed $name"
                    break
                fi
            done < <(get_all_providers)
        fi

        echo ""
        read -p "Press Enter to continue..."
    done
}

# Ensure default providers are registered in config
ensure_providers() {
    if ! has_enabled_providers; then
        # Auto-register all default providers
        while IFS= read -r provider; do
            [[ -z "$provider" ]] && continue
            set_provider "$provider" "true" "$(get_provider_default_path "$provider")"
        done < <(load_default_providers)
    fi
}

# ============================================================================
# Dependencies Functions
# ============================================================================

# Detect OS
get_os() {
    case "$(uname -s)" in
        Darwin*) echo "darwin" ;;
        Linux*) echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

# Check and install dependencies for a skill
check_dependencies() {
    local skill="$1"
    local skill_json="$SKILLS_DIR/$skill/skill.json"

    local deps_count
    deps_count=$(python3 -c "import json; print(len(json.load(open('$skill_json')).get('dependencies', [])))" 2>/dev/null || echo "0")

    [[ "$deps_count" == "0" ]] && return 0

    local os=$(get_os)
    local missing_deps=()

    for ((i=0; i<deps_count; i++)); do
        local dep_json name check_cmd install_cmd
        dep_json=$(python3 -c "import json; print(json.dumps(json.load(open('$skill_json'))['dependencies'][$i]))")

        name=$(echo "$dep_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('name',''))")
        check_cmd=$(echo "$dep_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('check',''))")
        install_cmd=$(echo "$dep_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('install',{}).get('$os',''))")

        if [[ -n "$check_cmd" ]] && ! eval "$check_cmd" &>/dev/null; then
            missing_deps+=("$name|$install_cmd")
        fi
    done

    [[ ${#missing_deps[@]} -eq 0 ]] && return 0

    echo ""
    style yellow "Missing dependencies:"
    for dep in "${missing_deps[@]}"; do
        local dep_name="${dep%%|*}"
        echo -e "  ${RED}✗${NC} $dep_name"
    done
    echo ""

    if confirm "Install missing dependencies?"; then
        for dep in "${missing_deps[@]}"; do
            local dep_name="${dep%%|*}"
            local dep_install="${dep##*|}"

            if [[ -z "$dep_install" ]]; then
                style red "No install command for $dep_name on $os"
                continue
            fi

            echo ""
            style cyan "Installing $dep_name..."
            echo -e "${DIM}Running: $dep_install${NC}"
            echo ""

            if eval "$dep_install"; then
                style green "✓ $dep_name installed"
            else
                style red "✗ Failed to install $dep_name"
                echo ""
                echo "You can install it manually with:"
                echo -e "  ${CYAN}$dep_install${NC}"
                return 1
            fi
        done
        echo ""
        style green "All dependencies installed"
    else
        echo ""
        style yellow "Skipping dependency installation"
        echo "You may need to install them manually for the skill to work."
        return 1
    fi

    return 0
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

# Compute checksum of skill files in repo
compute_skill_checksum() {
    local skill="$1"
    local skill_dir="$SKILLS_DIR/$skill"
    local skill_json="$skill_dir/skill.json"

    python3 -c "
import hashlib
import json
from pathlib import Path

skill_dir = Path('$skill_dir')
with open('$skill_json') as f:
    data = json.load(f)

hasher = hashlib.sha256()
for file_spec in sorted(data.get('files', [])):
    src = file_spec.split(':')[0] if ':' in file_spec else file_spec
    src_path = skill_dir / src
    if src_path.exists():
        hasher.update(src_path.read_bytes())

print(hasher.hexdigest()[:16])
"
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

# Get install path for a skill (for a specific provider)
get_install_path() {
    local skill="$1"
    local provider="$2"
    local base_path
    base_path=$(get_provider_path "$provider")
    echo "$base_path/$skill"
}

# Get primary install path (first enabled provider, for config storage)
get_primary_install_path() {
    local skill="$1"
    local provider
    provider=$(get_enabled_providers | head -1)
    [[ -z "$provider" ]] && return 1
    get_install_path "$skill" "$provider"
}

# Check if skill requires configuration
skill_needs_config() {
    local skill="$1"
    local field_count
    field_count=$(python3 -c "import json; print(len(json.load(open('$SKILLS_DIR/$skill/skill.json')).get('fields', [])))")
    [[ "$field_count" -gt 0 ]]
}

# Get skill status for a specific provider
get_skill_status_for_provider() {
    local skill="$1"
    local provider="$2"

    [[ -z "$provider" ]] && echo "not_installed" && return

    local install_path
    install_path=$(get_install_path "$skill" "$provider")

    if [[ ! -d "$install_path" ]]; then
        echo "not_installed"
        return
    fi

    local repo_checksum
    repo_checksum=$(compute_skill_checksum "$skill")

    # Check if outdated
    if [[ ! -f "$install_path/.checksum" ]]; then
        echo "outdated"
        return
    fi

    local installed_checksum
    installed_checksum=$(cat "$install_path/.checksum")
    if [[ "$installed_checksum" != "$repo_checksum" ]]; then
        echo "outdated"
        return
    fi

    # Check if configured (has credentials)
    if skill_needs_config "$skill"; then
        if [[ -f "$install_path/.env" ]]; then
            echo "configured"
        else
            echo "installed"
        fi
    else
        echo "configured"
    fi
}

# Get skill status for the selected provider (legacy, uses first enabled)
get_skill_status() {
    local skill="$1"
    local provider
    provider=$(get_enabled_providers | head -1)
    get_skill_status_for_provider "$skill" "$provider"
}

# Show skill info
show_skill_info() {
    local skill="$1"
    local skill_json="$SKILLS_DIR/$skill/skill.json"

    local title description version
    title=$(read_json "$skill_json" "title")
    description=$(read_json "$skill_json" "description")
    version=$(read_json "$skill_json" "version")

    header "$title"

    echo -e "${DIM}$description${NC}"
    echo ""
    echo -e "Version: ${BOLD}$version${NC}"
    echo ""

    # Show status for each enabled provider
    echo "Installation:"
    while IFS= read -r provider; do
        local pname pstatus path
        pname=$(get_provider_name "$provider")
        pstatus=$(get_skill_status_for_provider "$skill" "$provider")
        path=$(get_install_path "$skill" "$provider")

        local status_color status_text
        case "$pstatus" in
            not_installed) status_color="$YELLOW"; status_text="not installed" ;;
            installed) status_color="$CYAN"; status_text="needs config" ;;
            configured) status_color="$GREEN"; status_text="ready" ;;
            outdated) status_color="$YELLOW"; status_text="update available" ;;
        esac

        echo -e "  ${CYAN}$pname${NC}: ${status_color}$status_text${NC}"
        echo -e "    ${DIM}$path${NC}"
    done < <(get_enabled_providers)
    echo ""
}

# Check if skill has a test command
skill_has_test() {
    local skill="$1"
    local test_cmd
    test_cmd=$(read_json "$SKILLS_DIR/$skill/skill.json" "test_command")
    [[ -n "$test_cmd" ]]
}

# Get available actions for a skill (per provider)
get_actions() {
    local skill="$1"

    # Add per-provider actions
    while IFS= read -r provider; do
        [[ -z "$provider" ]] && continue
        local pname pstatus
        pname=$(get_provider_name "$provider")
        pstatus=$(get_skill_status_for_provider "$skill" "$provider")

        case "$pstatus" in
            not_installed) echo "Install in $pname" ;;
            outdated) echo "Update in $pname" ;;
            *) echo "Remove from $pname" ;;
        esac
    done < <(get_enabled_providers)

    echo "─────────────"

    # Global actions
    skill_has_test "$skill" && echo "Test"
    skill_needs_config "$skill" && echo "Edit credentials"
    skill_has_dependencies "$skill" && echo "Check dependencies"
    echo "Back"
}

# Check if skill has dependencies
skill_has_dependencies() {
    local skill="$1"
    local deps_count
    deps_count=$(python3 -c "import json; print(len(json.load(open('$SKILLS_DIR/$skill/skill.json')).get('dependencies', [])))" 2>/dev/null || echo "0")
    [[ "$deps_count" -gt 0 ]]
}

# Install skill files to a single provider
install_files_to_provider() {
    local skill="$1"
    local provider="$2"
    local skill_dir="$SKILLS_DIR/$skill"
    local skill_json="$skill_dir/skill.json"
    local install_path
    install_path=$(get_install_path "$skill" "$provider")

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

    # Save checksum
    compute_skill_checksum "$skill" > "$install_path/.checksum"

    # Copy central .env if exists
    local central_env="$CONFIG_DIR/$skill/.env"
    if [[ -f "$central_env" ]]; then
        cp "$central_env" "$install_path/.env"
        chmod 600 "$install_path/.env"
    fi
}

# Install skill files to all enabled providers
install_files() {
    local skill="$1"

    while IFS= read -r provider; do
        [[ -z "$provider" ]] && continue
        local name="$(get_provider_name "$provider")"
        echo -e "  Installing to ${CYAN}$name${NC}..."
        install_files_to_provider "$skill" "$provider"
    done < <(get_enabled_providers)
}

# Configure skill credentials
configure_skill() {
    local skill="$1"
    local skill_json="$SKILLS_DIR/$skill/skill.json"
    local primary_path
    primary_path=$(get_primary_install_path "$skill")

    [[ -z "$primary_path" ]] && style red "No providers configured" && return 1

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

        # Handle list type fields (e.g., multiple organizations)
        if [[ "$type" == "list" ]]; then
            env_content+=$(configure_list_field "$skill" "$field_json" "$primary_path")
            echo ""
            continue
        fi

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
        if [[ -f "$primary_path/.env" ]]; then
            existing=$(grep "^$env_var=" "$primary_path/.env" 2>/dev/null | cut -d= -f2- | tr -d '"' || true)
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

        [[ -n "$env_var" ]] && env_content+="$env_var=\"$value\"\n"
        echo ""
    done

    # Save to central location
    local central_dir="$CONFIG_DIR/$skill"
    mkdir -p "$central_dir"
    echo -e "$env_content" > "$central_dir/.env"
    chmod 600 "$central_dir/.env"

    # Run OAuth flow if skill uses top-level OAuth
    local has_oauth
    has_oauth=$(python3 -c "import json; print('true' if json.load(open('$skill_json')).get('oauth') else 'false')" 2>/dev/null || echo "false")

    if [[ "$has_oauth" == "true" ]]; then
        local client_id_val client_secret_val
        client_id_val=$(grep "CLIENT_ID=" "$central_dir/.env" | head -1 | cut -d= -f2- | tr -d '"')
        client_secret_val=$(grep "CLIENT_SECRET=" "$central_dir/.env" | head -1 | cut -d= -f2- | tr -d '"')

        if [[ -n "$client_id_val" && -n "$client_secret_val" ]]; then
            local tokens_json
            if tokens_json=$(run_skill_oauth "$skill" "$client_id_val" "$client_secret_val"); then
                local skill_upper
                skill_upper=$(echo "$skill" | tr '[:lower:]-' '[:upper:]_')
                local token_mapping
                token_mapping=$(python3 -c "import json; print(json.dumps(json.load(open('$skill_json')).get('oauth',{}).get('token_mapping',{'token':'ACCESS_TOKEN'})))")

                while IFS='=' read -r token_key env_suffix; do
                    local token_value
                    token_value=$(echo "$tokens_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('$token_key', ''))" 2>/dev/null || true)
                    if [[ -n "$token_value" ]]; then
                        echo "${skill_upper}_${env_suffix}=\"$token_value\"" >> "$central_dir/.env"
                    fi
                done < <(echo "$token_mapping" | python3 -c "import json,sys; [print(f'{k}={v}') for k,v in json.load(sys.stdin).items()]")

                style green "OAuth authorization complete"
            else
                return 1
            fi
        else
            style yellow "Warning: Could not find client credentials for OAuth"
        fi
    fi

    # Sync to all installed providers
    while IFS= read -r provider; do
        [[ -z "$provider" ]] && continue
        local install_path
        install_path=$(get_install_path "$skill" "$provider")
        [[ -d "$install_path" ]] || continue
        cp "$central_dir/.env" "$install_path/.env"
        chmod 600 "$install_path/.env"
    done < <(get_enabled_providers)

    style green "Configuration saved"
}

# Run OAuth flow for top-level skill OAuth
run_skill_oauth() {
    local skill="$1"
    local client_id="$2"
    local client_secret="$3"

    local skill_json="$SKILLS_DIR/$skill/skill.json"
    local oauth_json
    oauth_json=$(python3 -c "import json; print(json.dumps(json.load(open('$skill_json')).get('oauth', {})))")

    if [[ "$oauth_json" == "{}" ]]; then
        style red "Skill does not support OAuth" >&2
        return 1
    fi

    echo "" >&2
    style cyan "Starting OAuth authorization..." >&2
    echo "" >&2

    local tokens_json
    tokens_json=$(OAUTH_JSON="$oauth_json" OAUTH_CLIENT_ID="$client_id" OAUTH_CLIENT_SECRET="$client_secret" OAUTH_SCRIPT_DIR="$SCRIPT_DIR" python3 -c "
import json, sys, os
sys.path.insert(0, os.environ['OAUTH_SCRIPT_DIR'])
from oauth import run_oauth_flow

oauth_config = json.loads(os.environ['OAUTH_JSON'])
result = run_oauth_flow(oauth_config, os.environ['OAUTH_CLIENT_ID'], os.environ['OAUTH_CLIENT_SECRET'])
print(json.dumps(result))
" 2>&1)

    if echo "$tokens_json" | python3 -c "import json,sys; data=json.load(sys.stdin); sys.exit(0 if 'error' not in data else 1)" 2>/dev/null; then
        echo "$tokens_json"
        return 0
    else
        local error
        error=$(echo "$tokens_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error', 'Unknown error'))" 2>/dev/null || echo "$tokens_json")
        style red "Authorization failed: $error" >&2
        return 1
    fi
}

# Run OAuth flow for an account and save tokens
run_account_oauth() {
    local skill="$1"
    local field_json="$2"
    local account_slug="$3"
    local client_id="$4"
    local client_secret="$5"

    local item_oauth_json
    item_oauth_json=$(echo "$field_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('item_oauth', {})))")

    if [[ "$item_oauth_json" == "{}" ]]; then
        style red "Field does not support OAuth"
        return 1
    fi

    echo "" >&2
    style cyan "Authorizing account: $account_slug" >&2

    # Run OAuth flow using Python
    local tokens_json
    tokens_json=$(python3 -c "
import json
import sys
sys.path.insert(0, '$SCRIPT_DIR')
from oauth import run_oauth_flow

item_oauth = json.loads('''$item_oauth_json''')
result = run_oauth_flow(item_oauth, '$client_id', '$client_secret')
print(json.dumps(result))
" 2>&1)

    # Check for errors
    if echo "$tokens_json" | python3 -c "import json,sys; data=json.load(sys.stdin); sys.exit(0 if 'error' not in data else 1)" 2>/dev/null; then
        # Success - return the tokens
        echo "$tokens_json"
        return 0
    else
        local error
        error=$(echo "$tokens_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error', 'Unknown error'))" 2>/dev/null || echo "$tokens_json")
        style red "Authorization failed: $error" >&2
        return 1
    fi
}

# Configure a list-type field (e.g., multiple Sentry organizations)
configure_list_field() {
    local skill="$1"
    local field_json="$2"
    local primary_path="$3"

    local label name env_prefix item_fields_json item_oauth_json
    label=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('label','Items'))")
    name=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('name',''))")
    help=$(echo "$field_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('help',''))")
    item_fields_json=$(echo "$field_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('item_fields', [])))")
    item_oauth_json=$(echo "$field_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('item_oauth', {})))")
    local has_item_oauth="false"
    [[ "$item_oauth_json" != "{}" ]] && has_item_oauth="true"

    # Env prefix based on skill and field name (e.g., SENTRY_ORG_, DATABASE_DB_)
    local skill_upper=$(echo "$skill" | tr '[:lower:]-' '[:upper:]_')

    # Determine list prefix based on field name
    local list_prefix="ORG"
    if [[ "$name" == "databases" ]]; then
        list_prefix="DB"
    elif [[ "$name" == "organizations" ]]; then
        list_prefix="ORG"
    fi

    env_prefix="${skill_upper}_${list_prefix}_"

    echo -e "${BOLD}$label${NC}" >&2
    [[ -n "$help" ]] && echo -e "  ${DIM}$help${NC}" >&2
    echo "" >&2

    # Show redirect URI notice for OAuth accounts
    if [[ "$has_item_oauth" == "true" ]]; then
        echo -e "  ${CYAN}Redirect URI: http://localhost:9876/callback${NC}" >&2
        echo -e "  ${DIM}(Configure this in your OAuth app settings)${NC}" >&2
        echo "" >&2
    fi

    # Get existing items from .env (compatible with macOS BSD grep)
    # Use different marker field based on list type
    local marker_suffix="_TOKEN"
    if [[ "$name" == "databases" ]]; then
        marker_suffix="_HOST"
    elif [[ "$has_item_oauth" == "true" ]]; then
        # For OAuth accounts, look for REFRESH_TOKEN
        marker_suffix="_REFRESH_TOKEN"
    fi

    local existing_slugs=()
    if [[ -f "$primary_path/.env" ]]; then
        while IFS= read -r slug; do
            [[ -n "$slug" ]] && existing_slugs+=("$slug")
        done < <(grep -o "${env_prefix}[A-Z0-9_]*${marker_suffix}" "$primary_path/.env" 2>/dev/null | sed "s/^${env_prefix}//" | sed "s/${marker_suffix}$//" | tr '[:upper:]_' '[:lower:]-' | sort -u)
    fi

    local env_content=""
    local items_configured=0

    # Show existing items
    if [[ ${#existing_slugs[@]} -gt 0 ]]; then
        if [[ "$has_item_oauth" == "true" ]]; then
            echo -e "  ${DIM}Authorized accounts:${NC}" >&2
        else
            echo -e "  ${DIM}Existing items:${NC}" >&2
        fi
        for slug in "${existing_slugs[@]}"; do
            if [[ "$has_item_oauth" == "true" ]]; then
                echo -e "    ${GREEN}✓${NC} $slug" >&2
            else
                echo -e "    - $slug" >&2
            fi
        done
        echo "" >&2
    fi

    # Main loop for adding/managing items
    while true; do
        local action_options=("Add new item" "Done")
        if [[ ${#existing_slugs[@]} -gt 0 || $items_configured -gt 0 ]]; then
            if [[ "$has_item_oauth" == "true" ]]; then
                action_options=("Add new account" "Re-authorize account" "Remove account" "Done")
            else
                action_options=("Add new item" "Remove item" "Done")
            fi
        elif [[ "$has_item_oauth" == "true" ]]; then
            action_options=("Add new account" "Done")
        fi

        local action
        action=$(choose "What would you like to do?" "${action_options[@]}")

        case "$action" in
            "Add new item"|"Add new account")
                echo "" >&2
                local item_env=""
                local slug_value=""

                if [[ "$has_item_oauth" == "true" ]]; then
                    # OAuth account: only ask for slug, then run OAuth flow
                    echo -e "  ${BOLD}Account Name${NC} ${RED}(required)${NC}" >&2
                    echo -e "    ${DIM}Short name (e.g., 'work', 'personal')${NC}" >&2
                    slug_value=$(input_text "    Account Name" "")

                    if [[ -z "$slug_value" ]]; then
                        style red "Error: Account name is required" >&2
                        continue
                    fi

                    # Normalize slug
                    slug_value=$(echo "$slug_value" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

                    # Get client credentials from existing config or parent fields
                    local client_id client_secret
                    if [[ -f "$primary_path/.env" ]]; then
                        client_id=$(grep "CLIENT_ID=" "$primary_path/.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)
                        client_secret=$(grep "CLIENT_SECRET=" "$primary_path/.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)
                    fi

                    if [[ -z "$client_id" || -z "$client_secret" ]]; then
                        style red "Error: Client ID and Client Secret must be configured first" >&2
                        echo -e "  ${DIM}Please save the app credentials before adding accounts${NC}" >&2
                        continue
                    fi

                    # Run OAuth flow
                    local tokens_json
                    tokens_json=$(run_account_oauth "$skill" "$field_json" "$slug_value" "$client_id" "$client_secret")

                    if [[ $? -eq 0 ]] && [[ -n "$tokens_json" ]]; then
                        # Parse tokens and build env vars
                        local slug_upper=$(echo "$slug_value" | tr '[:lower:]-' '[:upper:]_')
                        local token_mapping
                        token_mapping=$(echo "$item_oauth_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('token_mapping', {'access_token': 'ACCESS_TOKEN', 'refresh_token': 'REFRESH_TOKEN', 'expires_in': 'TOKEN_EXPIRES'})))")

                        # Add each token to env_content
                        while IFS='=' read -r token_key env_suffix; do
                            local token_value
                            token_value=$(echo "$tokens_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('$token_key', ''))")
                            if [[ -n "$token_value" ]]; then
                                item_env+="${env_prefix}${slug_upper}_${env_suffix}=\"$token_value\"\n"
                            fi
                        done < <(echo "$token_mapping" | python3 -c "import json,sys; [print(f'{k}={v}') for k,v in json.load(sys.stdin).items()]")

                        if [[ -n "$item_env" ]]; then
                            env_content+="$item_env"
                            existing_slugs+=("$slug_value")
                            ((items_configured++))
                            style green "  Authorized: $slug_value" >&2
                        fi
                    fi
                else
                    # Standard list item: ask for all fields
                    local item_field_count
                    item_field_count=$(echo "$item_fields_json" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

                    for ((j=0; j<item_field_count; j++)); do
                        local ifield_json iname ilabel itype irequired idefault ihelp
                        ifield_json=$(echo "$item_fields_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)[$j]))")

                        iname=$(echo "$ifield_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('name',''))")
                        ilabel=$(echo "$ifield_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('label',''))")
                        itype=$(echo "$ifield_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('type','text'))")
                        irequired=$(echo "$ifield_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('required',False))")
                        idefault=$(echo "$ifield_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('default',''))")
                        ihelp=$(echo "$ifield_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('help',''))")

                        local irequired_mark=""
                        [[ "$irequired" == "True" ]] && irequired_mark=" ${RED}(required)${NC}"

                        echo -e "  ${BOLD}$ilabel${NC}$irequired_mark" >&2
                        [[ -n "$ihelp" ]] && echo -e "    ${DIM}$ihelp${NC}" >&2

                        local ivalue
                        if [[ "$itype" == "password" ]]; then
                            ivalue=$(input_password "    $ilabel")
                        else
                            ivalue=$(input_text "    $ilabel" "$idefault")
                        fi

                        # Validate required
                        if [[ "$irequired" == "True" ]] && [[ -z "$ivalue" ]]; then
                            style red "Error: $ilabel is required" >&2
                            continue 2
                        fi

                        # Store slug for env var naming
                        if [[ "$iname" == "slug" ]]; then
                            slug_value="$ivalue"
                        fi

                        # Build env var name: SENTRY_ORG_<SLUG>_<FIELD>
                        local slug_upper=$(echo "$slug_value" | tr '[:lower:]-' '[:upper:]_')
                        local field_upper=$(echo "$iname" | tr '[:lower:]-' '[:upper:]_')

                        # Store temporarily
                        if [[ "$iname" == "slug" ]]; then
                            # Slug is used in naming, not stored directly
                            :
                        else
                            item_env+="${env_prefix}${slug_upper}_${field_upper}=\"$ivalue\"\n"
                        fi
                    done

                    if [[ -n "$slug_value" ]]; then
                        env_content+="$item_env"
                        existing_slugs+=("$slug_value")
                        ((items_configured++))
                        style green "  Added: $slug_value" >&2
                    fi
                fi
                echo "" >&2
                ;;

            "Re-authorize account")
                if [[ ${#existing_slugs[@]} -eq 0 ]]; then
                    style yellow "No accounts to re-authorize" >&2
                    continue
                fi

                local reauth_options=("${existing_slugs[@]}" "Cancel")
                local to_reauth
                to_reauth=$(choose "Select account to re-authorize:" "${reauth_options[@]}")

                if [[ "$to_reauth" != "Cancel" && "$to_reauth" != "Back" ]]; then
                    # Get client credentials
                    local client_id client_secret
                    if [[ -f "$primary_path/.env" ]]; then
                        client_id=$(grep "CLIENT_ID=" "$primary_path/.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)
                        client_secret=$(grep "CLIENT_SECRET=" "$primary_path/.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)
                    fi

                    if [[ -z "$client_id" || -z "$client_secret" ]]; then
                        style red "Error: Client credentials not found" >&2
                        continue
                    fi

                    # Run OAuth flow
                    local tokens_json
                    tokens_json=$(run_account_oauth "$skill" "$field_json" "$to_reauth" "$client_id" "$client_secret")

                    if [[ $? -eq 0 ]] && [[ -n "$tokens_json" ]]; then
                        # Remove old tokens for this account from env_content
                        local slug_upper=$(echo "$to_reauth" | tr '[:lower:]-' '[:upper:]_')
                        env_content=$(echo -e "$env_content" | grep -v "${env_prefix}${slug_upper}_" || true)

                        # Add new tokens
                        local token_mapping
                        token_mapping=$(echo "$item_oauth_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('token_mapping', {'access_token': 'ACCESS_TOKEN', 'refresh_token': 'REFRESH_TOKEN', 'expires_in': 'TOKEN_EXPIRES'})))")

                        local new_tokens=""
                        while IFS='=' read -r token_key env_suffix; do
                            local token_value
                            token_value=$(echo "$tokens_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('$token_key', ''))")
                            if [[ -n "$token_value" ]]; then
                                new_tokens+="${env_prefix}${slug_upper}_${env_suffix}=\"$token_value\"\n"
                            fi
                        done < <(echo "$token_mapping" | python3 -c "import json,sys; [print(f'{k}={v}') for k,v in json.load(sys.stdin).items()]")

                        env_content+="$new_tokens"
                        style green "  Re-authorized: $to_reauth" >&2
                    fi
                fi
                echo "" >&2
                ;;

            "Remove item"|"Remove account")
                if [[ ${#existing_slugs[@]} -eq 0 && $items_configured -eq 0 ]]; then
                    style yellow "No items to remove" >&2
                    continue
                fi

                local remove_options=("${existing_slugs[@]}" "Cancel")
                local to_remove
                to_remove=$(choose "Select item to remove:" "${remove_options[@]}")

                if [[ "$to_remove" != "Cancel" && "$to_remove" != "Back" ]]; then
                    # Remove from existing_slugs array
                    local new_slugs=()
                    for s in "${existing_slugs[@]}"; do
                        [[ "$s" != "$to_remove" ]] && new_slugs+=("$s")
                    done
                    existing_slugs=("${new_slugs[@]}")

                    # Remove from env_content (won't persist removed items)
                    local slug_upper=$(echo "$to_remove" | tr '[:lower:]-' '[:upper:]_')
                    env_content=$(echo -e "$env_content" | grep -v "${env_prefix}${slug_upper}_" || true)

                    style yellow "  Removed: $to_remove" >&2
                fi
                echo "" >&2
                ;;

            "Done"|"Back")
                break
                ;;
        esac
    done

    # Rebuild env_content from existing items that weren't removed
    # (for items that existed before this session)
    if [[ -f "$primary_path/.env" ]]; then
        for slug in "${existing_slugs[@]}"; do
            local slug_upper=$(echo "$slug" | tr '[:lower:]-' '[:upper:]_')
            # Check if we already have this in env_content (newly added)
            if ! echo -e "$env_content" | grep -q "${env_prefix}${slug_upper}_"; then
                # Copy existing values from old .env
                while IFS= read -r line; do
                    env_content+="$line\n"
                done < <(grep "^${env_prefix}${slug_upper}_" "$primary_path/.env" 2>/dev/null || true)
            fi
        done
    fi

    echo "$env_content"
}

# Test skill
test_skill() {
    local skill="$1"
    local skill_json="$SKILLS_DIR/$skill/skill.json"
    local install_path
    install_path=$(get_primary_install_path "$skill")

    [[ -z "$install_path" ]] && style red "No providers configured" && return 1

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


# Uninstall skill from a specific provider
uninstall_from_provider() {
    local skill="$1"
    local provider="$2"
    local install_path
    install_path=$(get_install_path "$skill" "$provider")

    [[ -d "$install_path" ]] && rm -rf "$install_path"
}

# Uninstall skill from all providers
uninstall_skill() {
    local skill="$1"
    local any_uninstalled=false

    while IFS= read -r provider; do
        [[ -z "$provider" ]] && continue
        local name="$(get_provider_name "$provider")"
        local install_path
        install_path=$(get_install_path "$skill" "$provider")

        if [[ -d "$install_path" ]]; then
            rm -rf "$install_path"
            echo -e "  Removed from ${CYAN}$name${NC}"
            any_uninstalled=true
        fi
    done < <(get_enabled_providers)

    if [[ "$any_uninstalled" == "true" ]]; then
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

    # Check dependencies first
    check_dependencies "$skill" || return 1

    style cyan "Installing $skill..."
    install_files "$skill"
    style green "Files installed"
    echo ""

    if skill_needs_config "$skill"; then
        if confirm "Configure credentials now?"; then
            configure_skill "$skill"
        fi
    else
        style green "Ready to use (no configuration needed)"
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

do_update() {
    local skill="$1"

    style cyan "Updating $skill..."
    install_files "$skill"
    style green "Updated (credentials preserved)"
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

        # Get all skills info in a single python call
        local skills=()
        local skill_options=()
        local all_skills_info
        all_skills_info=$(python3 -c "
import json, hashlib
from pathlib import Path

skills_dir = Path('$SKILLS_DIR')
config_file = Path.home() / '.agent-skills' / 'config.json'
providers_file = Path('$PROVIDERS_FILE')

# Load default provider names
default_provider_names = {}
if providers_file.exists():
    with open(providers_file) as f:
        for p in json.load(f):
            default_provider_names[p['id']] = p['name'].split()[0]  # First word (e.g., 'Claude' from 'Claude Code')

with open(config_file) as f:
    config = json.load(f)

providers = [(p, info.get('path', ''), info.get('name', '')) for p, info in config.get('providers', {}).items() if info.get('enabled')]

for skill_dir in sorted(skills_dir.iterdir()):
    skill_json = skill_dir / 'skill.json'
    if not skill_json.exists():
        continue

    with open(skill_json) as f:
        data = json.load(f)

    title = data.get('title', skill_dir.name)
    skill_id = skill_dir.name

    # Compute repo checksum
    hasher = hashlib.sha256()
    for file_spec in sorted(data.get('files', [])):
        src = file_spec.split(':')[0] if ':' in file_spec else file_spec
        src_path = skill_dir / src
        if src_path.exists():
            hasher.update(src_path.read_bytes())
    repo_checksum = hasher.hexdigest()[:16]

    # Check status for each provider
    badges = ''
    for p, base_path, config_name in providers:
        # Get short name: from config, from defaults, or use ID
        name = config_name.split()[0] if config_name else default_provider_names.get(p, p)
        install_path = Path(base_path) / skill_id if base_path else None

        if not install_path or not install_path.is_dir():
            badges += f'[· {name}] '
            continue

        checksum_file = install_path / '.checksum'
        if not checksum_file.exists() or checksum_file.read_text().strip() != repo_checksum:
            badges += f'[↑ {name}] '
            continue

        badges += f'[✓ {name}] '

    print(f'{skill_id}|{title}|{badges.strip()}')
")

        local titles=()
        while IFS='|' read -r skill_id title badges; do
            skills+=("$skill_id")
            titles+=("$title")
            [[ -n "$badges" ]] && skill_options+=("$title  $badges") || skill_options+=("$title")
        done <<< "$all_skills_info"

        skill_options+=("─────────────")
        skill_options+=("Update Skills")
        skill_options+=("Manage Providers")
        skill_options+=("Exit")

        # Choose skill
        local choice
        choice=$(choose "Select a skill:" "${skill_options[@]}")

        [[ "$choice" == "Exit" || "$choice" == "Back" ]] && break
        [[ "$choice" == "Update Skills" ]] && { update_skills; continue; }
        [[ "$choice" == "Manage Providers" ]] && { manage_providers; continue; }
        [[ "$choice" == "─────────────" ]] && continue

        # Extract skill name from choice (remove badges after double space)
        local skill_title="${choice%%  \[*}"
        local selected_skill=""
        for i in "${!titles[@]}"; do
            if [[ "${titles[$i]}" == "$skill_title" ]]; then
                selected_skill="${skills[$i]}"
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

        local actions=()
        while IFS= read -r action; do
            actions+=("$action")
        done < <(get_actions "$skill")

        local action
        action=$(choose "Select action:" "${actions[@]}")

        case "$action" in
            "Test") do_test "$skill" ;;
            "Edit credentials") do_configure "$skill" ;;
            "Check dependencies") check_dependencies "$skill" ;;
            "─────────────") continue ;;
            "Back") break ;;
            Install\ in\ *)
                # Dynamic install: extract provider name
                local pname="${action#Install in }"
                # Find provider ID by name
                while IFS= read -r provider; do
                    local name="$(get_provider_name "$provider")"
                    if [[ "$name" == "$pname" ]]; then
                        check_dependencies "$skill" && install_files_to_provider "$skill" "$provider" && style green "Installed in $name"
                        break
                    fi
                done < <(get_enabled_providers)
                ;;
            Update\ in\ *)
                # Dynamic update: extract provider name
                local pname="${action#Update in }"
                while IFS= read -r provider; do
                    local name="$(get_provider_name "$provider")"
                    if [[ "$name" == "$pname" ]]; then
                        check_dependencies "$skill" && install_files_to_provider "$skill" "$provider" && style green "Updated in $name"
                        break
                    fi
                done < <(get_enabled_providers)
                ;;
            Remove\ from\ *)
                # Dynamic remove: extract provider name
                local pname="${action#Remove from }"
                while IFS= read -r provider; do
                    local name="$(get_provider_name "$provider")"
                    if [[ "$name" == "$pname" ]]; then
                        uninstall_from_provider "$skill" "$provider"
                        style yellow "Removed from $name"
                        break
                    fi
                done < <(get_enabled_providers)
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

# ============================================================================
# Entry Point
# ============================================================================

# Initialize and ensure providers are configured
init_config
ensure_providers

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
        update) do_update "$skill" ;;
        connect) do_configure "$skill" ;;
        test) do_test "$skill" ;;
        uninstall) do_uninstall "$skill" ;;
        *)
            style red "Unknown action: $action"
            echo "Available: install, update, connect, test, uninstall"
            exit 1
            ;;
    esac
fi
