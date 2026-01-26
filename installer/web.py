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
                skills.append(data)
    return skills

def get_install_path(skill_data):
    """Get expanded install path."""
    path = skill_data.get("install_path", "")
    return os.path.expanduser(path)

def skill_needs_config(skill_data):
    """Check if skill requires configuration."""
    return len(skill_data.get("fields", [])) > 0

def get_skill_status(skill_id, skill_data):
    """Get installation status of a skill."""
    install_path = get_install_path(skill_data)

    if not os.path.isdir(install_path):
        return "not_installed"

    # Check if outdated (no checksum = old install, treat as outdated)
    checksum_file = os.path.join(install_path, ".checksum")
    repo_checksum = compute_skill_checksum(skill_id, skill_data)

    if not os.path.isfile(checksum_file):
        return "outdated"

    with open(checksum_file) as f:
        installed_checksum = f.read().strip()
    if installed_checksum != repo_checksum:
        return "outdated"

    # Skills without fields are configured once installed
    if not skill_needs_config(skill_data):
        return "configured"

    if not os.path.isfile(os.path.join(install_path, ".env")):
        return "installed"

    return "configured"

def install_files(skill_id, skill_data):
    """Install skill files."""
    skill_dir = SKILLS_DIR / skill_id
    install_path = get_install_path(skill_data)

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

    # Save checksum
    checksum = compute_skill_checksum(skill_id, skill_data)
    checksum_path = Path(install_path) / ".checksum"
    checksum_path.write_text(checksum)

def save_config(skill_data, config):
    """Save configuration to .env file."""
    install_path = get_install_path(skill_data)
    env_path = os.path.join(install_path, ".env")

    lines = []
    for field in skill_data.get("fields", []):
        env_var = field.get("env_var", "")
        value = config.get(field["name"], "")
        if env_var:
            lines.append(f'{env_var}="{value}"')

    with open(env_path, "w") as f:
        f.write("\n".join(lines) + "\n")

    os.chmod(env_path, 0o600)

def get_current_config(skill_data):
    """Get current configuration values."""
    install_path = get_install_path(skill_data)
    env_path = os.path.join(install_path, ".env")

    config = {}
    if os.path.isfile(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if "=" in line:
                    key, value = line.split("=", 1)
                    value = value.strip('"').strip("'")
                    # Map env_var back to field name
                    for field in skill_data.get("fields", []):
                        if field.get("env_var") == key:
                            config[field["name"]] = value
                            break

    return config

def test_skill(skill_id, skill_data):
    """Run skill test command."""
    install_path = get_install_path(skill_data)
    test_cmd = skill_data.get("test_command", "")

    if not test_cmd:
        return {"success": False, "output": "No test command defined"}

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

def clear_auth(skill_data):
    """Remove credentials."""
    install_path = get_install_path(skill_data)
    env_path = os.path.join(install_path, ".env")

    if os.path.isfile(env_path):
        os.remove(env_path)
        return True
    return False

def uninstall_skill(skill_data):
    """Remove skill completely."""
    install_path = get_install_path(skill_data)

    if os.path.isdir(install_path):
        import shutil
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
        elif path == "/api/skills":
            self.send_json(get_skills())
        elif path.startswith("/api/skills/"):
            skill_id = path.split("/")[3]
            skills = {s["id"]: s for s in get_skills()}
            if skill_id in skills:
                skill = skills[skill_id]
                skill["config"] = get_current_config(skill)
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

        skills = {s["id"]: s for s in get_skills()}

        if path.startswith("/api/skills/") and path.endswith("/install"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                install_files(skill_id, skills[skill_id])
                self.send_json({"success": True, "message": "Installed"})
            else:
                self.send_json({"error": "Skill not found"}, 404)

        elif path.startswith("/api/skills/") and path.endswith("/configure"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                skill = skills[skill_id]
                install_path = get_install_path(skill)
                if not os.path.isdir(install_path):
                    install_files(skill_id, skill)
                save_config(skill, data)
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

        elif path.startswith("/api/skills/") and path.endswith("/clear-auth"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                clear_auth(skills[skill_id])
                self.send_json({"success": True, "message": "Credentials removed"})
            else:
                self.send_json({"error": "Skill not found"}, 404)

        elif path.startswith("/api/skills/") and path.endswith("/uninstall"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
                uninstall_skill(skills[skill_id])
                self.send_json({"success": True, "message": "Uninstalled"})
            else:
                self.send_json({"error": "Skill not found"}, 404)

        elif path.startswith("/api/skills/") and path.endswith("/update"):
            skill_id = path.split("/")[3]
            if skill_id in skills:
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
