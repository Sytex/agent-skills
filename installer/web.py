#!/usr/bin/env python3
"""
Agent Skills Installer - Web Server
Uses only Python stdlib, no external dependencies.
"""

import hashlib
import http.server
import json
import os
import subprocess
import sys
import urllib.parse
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
SKILLS_DIR = SCRIPT_DIR.parent / "skills"
TEMPLATES_DIR = SCRIPT_DIR / "templates"

# Provider configuration
CONFIG_DIR = Path.home() / ".agent-skills"
CONFIG_FILE = CONFIG_DIR / "config.json"

AVAILABLE_PROVIDERS = {
    "claude": {"name": "Claude Code", "path": str(Path.home() / ".claude/skills")},
    "codex": {"name": "Codex CLI", "path": str(Path.home() / ".codex/skills")},
    "gemini": {"name": "Gemini CLI", "path": str(Path.home() / ".gemini/skills")},
}


def init_config():
    """Initialize config directory and file with all providers enabled by default."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    if not CONFIG_FILE.exists():
        default_config = {
            "providers": {
                "claude": {
                    "enabled": True,
                    "path": str(Path.home() / ".claude/skills")
                },
                "codex": {
                    "enabled": True,
                    "path": str(Path.home() / ".codex/skills")
                },
                "gemini": {
                    "enabled": True,
                    "path": str(Path.home() / ".gemini/skills")
                }
            },
            "selected_provider": "claude"
        }
        CONFIG_FILE.write_text(json.dumps(default_config, indent=2))


def load_config():
    """Load provider configuration."""
    init_config()
    with open(CONFIG_FILE) as f:
        return json.load(f)


def save_config(config):
    """Save provider configuration."""
    init_config()
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)


def get_enabled_providers():
    """Get list of enabled provider IDs."""
    config = load_config()
    return [
        pid for pid, info in config.get("providers", {}).items()
        if info.get("enabled", False)
    ]


def get_provider_path(provider_id):
    """Get install path for a provider."""
    config = load_config()
    return config.get("providers", {}).get(provider_id, {}).get("path", "")


def get_providers_status():
    """Get all providers with their status."""
    config = load_config()
    selected = get_selected_provider()
    result = []
    for pid, info in AVAILABLE_PROVIDERS.items():
        provider_config = config.get("providers", {}).get(pid, {})
        result.append({
            "id": pid,
            "name": info["name"],
            "default_path": info["path"],
            "enabled": provider_config.get("enabled", False),
            "path": provider_config.get("path", info["path"]),
            "selected": pid == selected,
        })
    return result


def get_selected_provider():
    """Get the currently selected provider for viewing."""
    config = load_config()
    selected = config.get("selected_provider", "")
    enabled = get_enabled_providers()

    if not selected or selected not in enabled:
        return enabled[0] if enabled else ""
    return selected


def set_selected_provider(provider_id):
    """Set the selected provider for viewing."""
    config = load_config()
    config["selected_provider"] = provider_id
    save_config(config)


def set_provider(provider_id, enabled, path=None):
    """Enable or disable a provider."""
    config = load_config()
    if "providers" not in config:
        config["providers"] = {}

    if path is None:
        path = AVAILABLE_PROVIDERS.get(provider_id, {}).get("path", "")

    config["providers"][provider_id] = {"enabled": enabled, "path": path}
    save_config(config)


def check_for_updates():
    """Check if there are updates available in the remote repository."""
    repo_dir = SCRIPT_DIR.parent

    fetch_result = subprocess.run(
        ["git", "fetch"],
        cwd=repo_dir,
        capture_output=True,
        text=True
    )
    if fetch_result.returncode != 0:
        return {"has_updates": False, "error": fetch_result.stderr.strip()}

    result = subprocess.run(
        ["git", "status", "-uno"],
        cwd=repo_dir,
        capture_output=True,
        text=True
    )
    has_updates = "Your branch is behind" in result.stdout
    return {"has_updates": has_updates}


def update_repo():
    """Pull latest changes from git repository."""
    repo_dir = SCRIPT_DIR.parent
    result = subprocess.run(
        ["git", "pull"],
        cwd=repo_dir,
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        error = result.stderr.strip() or result.stdout.strip() or "Git pull failed"
        return {"success": False, "error": error}

    output = result.stdout.strip()
    if "Already up to date" in output:
        return {"success": True, "message": "Already up to date"}
    return {"success": True, "message": "Skills updated"}


def compute_skill_checksum(skill_id, skill_data):
    """Compute checksum of skill files in the repo."""
    skill_dir = SKILLS_DIR / skill_id
    files = skill_data.get("files", [])

    hasher = hashlib.sha256()
    for file_spec in sorted(files):
        src = file_spec.split(":")[0] if ":" in file_spec else file_spec
        src_path = skill_dir / src
        if src_path.exists():
            hasher.update(src_path.read_bytes())

    return hasher.hexdigest()[:16]


def get_skills():
    """Get list of available skills."""
    skills = []
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        skill_json = skill_dir / "skill.json"
        if skill_json.exists():
            with open(skill_json) as f:
                data = json.load(f)
                data["id"] = skill_dir.name
                data["status"] = get_skill_status(skill_dir.name, data)
                data["provider_status"] = get_skill_provider_status(skill_dir.name, data)
                skills.append(data)
    return skills


def get_install_path(skill_id, provider_id):
    """Get install path for a skill in a specific provider."""
    base_path = get_provider_path(provider_id)
    return os.path.join(base_path, skill_id) if base_path else ""


def get_primary_install_path(skill_id):
    """Get install path for first enabled provider."""
    providers = get_enabled_providers()
    if not providers:
        return ""
    return get_install_path(skill_id, providers[0])


def skill_needs_config(skill_data):
    """Check if skill requires configuration."""
    return len(skill_data.get("fields", [])) > 0


def get_skill_provider_status(skill_id, skill_data):
    """Get installation status per provider."""
    result = {}
    repo_checksum = compute_skill_checksum(skill_id, skill_data)

    for provider_id in get_enabled_providers():
        install_path = get_install_path(skill_id, provider_id)
        if not install_path or not os.path.isdir(install_path):
            result[provider_id] = "not_installed"
            continue

        checksum_file = os.path.join(install_path, ".checksum")
        if not os.path.isfile(checksum_file):
            result[provider_id] = "outdated"
            continue

        with open(checksum_file) as f:
            installed_checksum = f.read().strip()
        if installed_checksum != repo_checksum:
            result[provider_id] = "outdated"
            continue

        result[provider_id] = "installed"

    return result


def get_skill_status(skill_id, skill_data):
    """Get installation status of a skill for the selected provider."""
    provider_id = get_selected_provider()
    if not provider_id:
        return "not_installed"

    install_path = get_install_path(skill_id, provider_id)
    if not install_path or not os.path.isdir(install_path):
        return "not_installed"

    repo_checksum = compute_skill_checksum(skill_id, skill_data)

    checksum_file = os.path.join(install_path, ".checksum")
    if not os.path.isfile(checksum_file):
        return "outdated"

    with open(checksum_file) as f:
        installed_checksum = f.read().strip()
    if installed_checksum != repo_checksum:
        return "outdated"

    if not skill_needs_config(skill_data):
        return "configured"

    if os.path.isfile(os.path.join(install_path, ".env")):
        return "configured"

    return "installed"


def install_files_to_provider(skill_id, skill_data, provider_id):
    """Install skill files to a specific provider."""
    skill_dir = SKILLS_DIR / skill_id
    install_path = get_install_path(skill_id, provider_id)

    if not install_path:
        return False

    os.makedirs(install_path, exist_ok=True)

    for file_spec in skill_data.get("files", []):
        if ":" in file_spec:
            src, dst = file_spec.split(":", 1)
        else:
            src = file_spec
            dst = os.path.basename(file_spec)

        src_path = skill_dir / src
        dst_path = Path(install_path) / dst

        if src_path.exists():
            dst_path.write_bytes(src_path.read_bytes())
            os.chmod(dst_path, 0o755)

    checksum = compute_skill_checksum(skill_id, skill_data)
    checksum_path = Path(install_path) / ".checksum"
    checksum_path.write_text(checksum)

    # Copy central .env if exists
    central_env = get_central_config_path(skill_id) / ".env"
    if central_env.exists():
        provider_env = Path(install_path) / ".env"
        provider_env.write_text(central_env.read_text())
        os.chmod(provider_env, 0o600)

    return True


def install_files(skill_id, skill_data):
    """Install skill files to all enabled providers."""
    results = []
    for provider_id in get_enabled_providers():
        success = install_files_to_provider(skill_id, skill_data, provider_id)
        results.append({"provider": provider_id, "success": success})
    return results


def get_central_config_path(skill_id):
    """Get central config directory for a skill."""
    return CONFIG_DIR / skill_id


def save_skill_config(skill_id, skill_data, config):
    """Save configuration to central location and sync to installed providers."""
    lines = []
    skill_upper = skill_id.upper().replace("-", "_")

    for field in skill_data.get("fields", []):
        field_type = field.get("type", "text")
        field_name = field.get("name", "")

        # Handle list type fields (e.g., multiple organizations)
        if field_type == "list":
            items = config.get(field_name, [])
            if isinstance(items, list):
                for item in items:
                    slug = item.get("slug", "")
                    if not slug:
                        continue
                    slug_upper = slug.upper().replace("-", "_")
                    env_prefix = f"{skill_upper}_ORG_{slug_upper}_"

                    for item_field in field.get("item_fields", []):
                        item_field_name = item_field.get("name", "")
                        if item_field_name == "slug":
                            continue  # slug is used in naming, not stored directly
                        item_value = item.get(item_field_name, item_field.get("default", ""))
                        field_upper = item_field_name.upper().replace("-", "_")
                        lines.append(f'{env_prefix}{field_upper}="{item_value}"')
        else:
            env_var = field.get("env_var", "")
            value = config.get(field_name, "")
            if env_var:
                lines.append(f'{env_var}="{value}"')

    # Handle default_org field if present
    if "default_org" in config and config["default_org"]:
        lines.append(f'{skill_upper}_DEFAULT_ORG="{config["default_org"]}"')

    content = "\n".join(lines) + "\n"

    # Save to central location
    central_path = get_central_config_path(skill_id)
    central_path.mkdir(parents=True, exist_ok=True)
    env_path = central_path / ".env"
    env_path.write_text(content)
    os.chmod(env_path, 0o600)

    # Sync to all installed providers
    sync_config_to_providers(skill_id)


def sync_config_to_providers(skill_id):
    """Copy central .env to all providers where skill is installed."""
    central_env = get_central_config_path(skill_id) / ".env"
    if not central_env.exists():
        return

    content = central_env.read_text()
    for provider_id in get_enabled_providers():
        install_path = get_install_path(skill_id, provider_id)
        if install_path and os.path.isdir(install_path):
            provider_env = Path(install_path) / ".env"
            provider_env.write_text(content)
            os.chmod(provider_env, 0o600)


def get_current_config(skill_id, skill_data):
    """Get current configuration values from central location."""
    central_env = get_central_config_path(skill_id) / ".env"

    config = {}
    if not central_env.exists():
        return config

    skill_upper = skill_id.upper().replace("-", "_")
    env_content = central_env.read_text()

    # Parse all env vars
    env_vars = {}
    for line in env_content.splitlines():
        line = line.strip()
        if "=" in line:
            key, value = line.split("=", 1)
            env_vars[key] = value.strip('"').strip("'")

    for field in skill_data.get("fields", []):
        field_type = field.get("type", "text")
        field_name = field.get("name", "")

        # Handle list type fields
        if field_type == "list":
            items = []
            # Find all organization slugs from env vars
            # Pattern: SENTRY_ORG_<SLUG>_TOKEN
            env_prefix = f"{skill_upper}_ORG_"
            slugs = set()
            for key in env_vars:
                if key.startswith(env_prefix) and key.endswith("_TOKEN"):
                    # Extract slug: SENTRY_ORG_SYTEX_EU_TOKEN -> sytex-eu
                    slug_part = key[len(env_prefix):-6]  # Remove prefix and _TOKEN
                    slug = slug_part.lower().replace("_", "-")
                    slugs.add(slug)

            for slug in sorted(slugs):
                slug_upper = slug.upper().replace("-", "_")
                item = {"slug": slug}
                for item_field in field.get("item_fields", []):
                    item_field_name = item_field.get("name", "")
                    if item_field_name == "slug":
                        continue
                    field_upper = item_field_name.upper().replace("-", "_")
                    env_key = f"{env_prefix}{slug_upper}_{field_upper}"
                    item[item_field_name] = env_vars.get(env_key, item_field.get("default", ""))
                items.append(item)

            config[field_name] = items
        else:
            env_var = field.get("env_var", "")
            if env_var and env_var in env_vars:
                config[field_name] = env_vars[env_var]

    # Get default_org if present
    default_org_key = f"{skill_upper}_DEFAULT_ORG"
    if default_org_key in env_vars:
        config["default_org"] = env_vars[default_org_key]

    return config


def test_skill(skill_id, skill_data):
    """Run skill test command."""
    install_path = get_primary_install_path(skill_id)
    test_cmd = skill_data.get("test_command", "")

    if not test_cmd:
        return {"success": False, "output": "No test command defined"}

    if not install_path:
        return {"success": False, "output": "No providers configured"}

    executable = os.path.join(install_path, skill_id)
    if not os.path.isfile(executable):
        return {"success": False, "output": f"Executable not found: {executable}"}

    cmd = f"{executable} {test_cmd}"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    output = result.stdout + result.stderr
    return {
        "success": result.returncode == 0,
        "output": output or "(no output)"
    }


def clear_auth(skill_id, skill_data):
    """Remove credentials from all providers."""
    removed = False
    for provider_id in get_enabled_providers():
        install_path = get_install_path(skill_id, provider_id)
        if install_path:
            env_path = os.path.join(install_path, ".env")
            if os.path.isfile(env_path):
                os.remove(env_path)
                removed = True
    return removed


def run_oauth_flow(skill_id, skill_data, client_id, client_secret):
    """Run OAuth flow for a skill."""
    from oauth import run_oauth_flow as oauth_flow

    oauth_config = skill_data.get("oauth")
    if not oauth_config:
        return {"error": "Skill does not support OAuth"}

    result = oauth_flow(oauth_config, client_id, client_secret)
    return result


def save_oauth_tokens(skill_id, skill_data, tokens, client_id, client_secret):
    """Save OAuth tokens to skill config."""
    # Build env content from fields + tokens
    lines = []

    # Add client credentials
    for field in skill_data.get("fields", []):
        env_var = field.get("env_var", "")
        if "CLIENT_ID" in env_var:
            lines.append(f'{env_var}="{client_id}"')
        elif "CLIENT_SECRET" in env_var:
            lines.append(f'{env_var}="{client_secret}"')

    # Add tokens
    oauth_config = skill_data.get("oauth", {})
    token_mapping = oauth_config.get("token_mapping", {
        "access_token": "ACCESS_TOKEN",
        "refresh_token": "REFRESH_TOKEN",
        "expires_in": "TOKEN_EXPIRES_IN",
    })

    prefix = skill_id.upper()
    for token_key, env_suffix in token_mapping.items():
        if token_key in tokens:
            value = tokens[token_key]
            lines.append(f'{prefix}_{env_suffix}="{value}"')

    # Add any extra fields from token response
    for key, value in tokens.items():
        if key not in token_mapping and value and isinstance(value, (str, int)):
            env_key = f"{prefix}_{key.upper()}"
            lines.append(f'{env_key}="{value}"')

    content = "\n".join(lines) + "\n"

    # Save to central location
    central_path = get_central_config_path(skill_id)
    central_path.mkdir(parents=True, exist_ok=True)
    env_path = central_path / ".env"
    env_path.write_text(content)
    os.chmod(env_path, 0o600)

    # Sync to providers
    sync_config_to_providers(skill_id)


def uninstall_skill(skill_id, skill_data):
    """Remove skill from all providers."""
    import shutil
    removed = False
    for provider_id in get_enabled_providers():
        install_path = get_install_path(skill_id, provider_id)
        if install_path and os.path.isdir(install_path):
            shutil.rmtree(install_path)
            removed = True
    return removed


def uninstall_skill_from_provider(skill_id, provider_id):
    """Remove skill from a specific provider."""
    import shutil
    install_path = get_install_path(skill_id, provider_id)
    if install_path and os.path.isdir(install_path):
        shutil.rmtree(install_path)
        return True
    return False


class RequestHandler(http.server.BaseHTTPRequestHandler):
    """HTTP request handler for the installer."""

    def log_message(self, format, *args):
        """Suppress default logging."""
        pass

    def send_json(self, data, status=200):
        """Send JSON response."""
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        """Handle CORS preflight."""
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        """Handle GET requests."""
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/" or path == "/index.html":
            self.serve_html()
        elif path == "/api/providers":
            self.send_json(get_providers_status())
        elif path == "/api/skills":
            self.send_json(get_skills())
        elif path == "/api/check-updates":
            self.send_json(check_for_updates())
        elif path.startswith("/api/skills/"):
            skill_id = path.split("/")[3]
            skills = {s["id"]: s for s in get_skills()}
            if skill_id in skills:
                skill = skills[skill_id]
                skill["config"] = get_current_config(skill_id, skill)
                self.send_json(skill)
            else:
                self.send_json({"error": "Skill not found"}, 404)
        else:
            self.send_error(404)

    def do_POST(self):
        """Handle POST requests."""
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode() if content_length else "{}"
        data = json.loads(body) if body else {}

        # Provider endpoints
        if path == "/api/providers":
            provider_id = data.get("id")
            enabled = data.get("enabled", False)
            custom_path = data.get("path")
            if provider_id in AVAILABLE_PROVIDERS:
                set_provider(provider_id, enabled, custom_path)
                self.send_json({"success": True, "message": f"Provider {'enabled' if enabled else 'disabled'}"})
            else:
                self.send_json({"error": "Unknown provider"}, 400)
            return

        if path == "/api/providers/select":
            provider_id = data.get("id")
            if provider_id in AVAILABLE_PROVIDERS:
                set_selected_provider(provider_id)
                self.send_json({"success": True, "message": f"Selected {provider_id}"})
            else:
                self.send_json({"error": "Unknown provider"}, 400)
            return

        if path == "/api/update":
            result = update_repo()
            self.send_json(result)
            return

        skills = {s["id"]: s for s in get_skills()}

        if path.startswith("/api/skills/") and "/install/" in path:
            # Install to specific provider: /api/skills/{id}/install/{provider}
            parts = path.split("/")
            skill_id = parts[3]
            provider_id = parts[5]
            if skill_id in skills:
                success = install_files_to_provider(skill_id, skills[skill_id], provider_id)
                if success:
                    self.send_json({"success": True, "message": "Installed"})
                    return
                self.send_json({"error": "Failed to install"}, 400)
                return
            self.send_json({"error": "Skill not found"}, 404)
            return

        if path.startswith("/api/skills/") and "/uninstall/" in path:
            # Uninstall from specific provider: /api/skills/{id}/uninstall/{provider}
            parts = path.split("/")
            skill_id = parts[3]
            provider_id = parts[5]
            if skill_id in skills:
                uninstall_skill_from_provider(skill_id, provider_id)
                self.send_json({"success": True, "message": "Removed"})
                return
            self.send_json({"error": "Skill not found"}, 404)
            return

        if path.startswith("/api/skills/") and path.endswith("/install"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                if not get_enabled_providers():
                    self.send_json({"error": "No providers configured"}, 400)
                    return
                results = install_files(skill_id, skills[skill_id])
                self.send_json({"success": True, "message": "Installed", "results": results})
            else:
                self.send_json({"error": "Skill not found"}, 404)

        elif path.startswith("/api/skills/") and path.endswith("/configure"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                skill = skills[skill_id]
                if not get_enabled_providers():
                    self.send_json({"error": "No providers configured"}, 400)
                    return
                # Install if not already installed
                primary_path = get_primary_install_path(skill_id)
                if not primary_path or not os.path.isdir(primary_path):
                    install_files(skill_id, skill)
                save_skill_config(skill_id, skill, data)
                self.send_json({"success": True, "message": "Configured"})
            else:
                self.send_json({"error": "Skill not found"}, 404)

        elif path.startswith("/api/skills/") and path.endswith("/test"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                result = test_skill(skill_id, skills[skill_id])
                self.send_json(result)
            else:
                self.send_json({"error": "Skill not found"}, 404)

        elif path.startswith("/api/skills/") and path.endswith("/oauth"):
            skill_id = path.split("/")[3]
            if skill_id not in skills:
                self.send_json({"error": "Skill not found"}, 404)
                return

            skill = skills[skill_id]
            if not skill.get("oauth"):
                self.send_json({"error": "Skill does not support OAuth"}, 400)
                return

            client_id = data.get("client_id")
            client_secret = data.get("client_secret")
            if not client_id or not client_secret:
                self.send_json({"error": "client_id and client_secret required"}, 400)
                return

            # Install files first if needed
            if not get_enabled_providers():
                self.send_json({"error": "No providers configured"}, 400)
                return

            primary_path = get_primary_install_path(skill_id)
            if not primary_path or not os.path.isdir(primary_path):
                install_files(skill_id, skill)

            # Run OAuth flow
            result = run_oauth_flow(skill_id, skill, client_id, client_secret)

            if "error" in result:
                self.send_json({"error": result["error"]}, 400)
                return

            # Save tokens
            save_oauth_tokens(skill_id, skill, result, client_id, client_secret)
            self.send_json({"success": True, "message": "OAuth authorization complete"})

        elif path.startswith("/api/skills/") and path.endswith("/clear-auth"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                clear_auth(skill_id, skills[skill_id])
                self.send_json({"success": True, "message": "Credentials removed"})
            else:
                self.send_json({"error": "Skill not found"}, 404)

        elif path.startswith("/api/skills/") and path.endswith("/uninstall"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                uninstall_skill(skill_id, skills[skill_id])
                self.send_json({"success": True, "message": "Uninstalled"})
            else:
                self.send_json({"error": "Skill not found"}, 404)

        elif path.startswith("/api/skills/") and path.endswith("/update"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                if not get_enabled_providers():
                    self.send_json({"error": "No providers configured"}, 400)
                    return
                install_files(skill_id, skills[skill_id])
                self.send_json({"success": True, "message": "Updated"})
            else:
                self.send_json({"error": "Skill not found"}, 404)

        else:
            self.send_error(404)

    def serve_html(self):
        """Serve the main HTML page."""
        html_path = TEMPLATES_DIR / "index.html"
        if html_path.exists():
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(html_path.read_bytes())
        else:
            self.send_error(404, "Template not found")


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765

    server = http.server.HTTPServer(("localhost", port), RequestHandler)
    print(f"Server running at http://localhost:{port}")

    server.serve_forever()


if __name__ == "__main__":
    main()
