#!/usr/bin/env python3
"""
OAuth 2.0 Authorization Code Flow handler.
Provides a local callback server for CLI OAuth flows.
"""

import http.server
import json
import secrets
import socket
import socketserver
import subprocess
import sys
import threading
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


# Fixed port for OAuth callback - users must configure this in their OAuth app
OAUTH_CALLBACK_PORT = 9876
OAUTH_REDIRECT_URI = f"http://localhost:{OAUTH_CALLBACK_PORT}/callback"


def find_free_port():
    """Check if the fixed OAuth port is available."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        result = s.connect_ex(("localhost", OAUTH_CALLBACK_PORT))
        if result == 0:
            # Port is in use
            raise RuntimeError(f"Port {OAUTH_CALLBACK_PORT} is in use. Close the application using it and try again.")
        return OAUTH_CALLBACK_PORT


def open_browser(url):
    """Open URL in default browser."""
    opened = False
    if sys.platform == "darwin":
        try:
            subprocess.run(["open", url], check=False)
            opened = True
        except FileNotFoundError:
            pass
    elif sys.platform == "linux":
        for cmd in ["xdg-open", "gnome-open", "kde-open", "sensible-browser"]:
            try:
                subprocess.run([cmd, url], check=False)
                opened = True
                break
            except FileNotFoundError:
                continue

    if not opened:
        import webbrowser
        webbrowser.open(url)


class OAuthCallbackHandler(http.server.BaseHTTPRequestHandler):
    """Handle OAuth callback requests."""

    def log_message(self, format, *args):
        pass

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)

        if parsed.path == "/callback":
            code = params.get("code", [None])[0]
            state = params.get("state", [None])[0]
            error = params.get("error", [None])[0]

            if error:
                self.server.oauth_error = params.get("error_description", [error])[0]
                self.send_error_page(f"Authorization failed: {self.server.oauth_error}")
            elif code:
                if state and self.server.expected_state and state != self.server.expected_state:
                    self.server.oauth_error = "State mismatch - possible CSRF attack"
                    self.send_error_page(self.server.oauth_error)
                else:
                    self.server.oauth_code = code
                    self.send_success_page()
            else:
                self.server.oauth_error = "No authorization code received"
                self.send_error_page(self.server.oauth_error)

            threading.Thread(target=self.server.shutdown).start()
        else:
            self.send_error(404)

    def send_success_page(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        html = """<!DOCTYPE html>
<html>
<head>
    <title>Authorization Successful</title>
    <style>
        body { font-family: -apple-system, system-ui, sans-serif; display: flex;
               justify-content: center; align-items: center; height: 100vh; margin: 0;
               background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .card { background: white; padding: 3rem; border-radius: 1rem; text-align: center;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3); max-width: 400px; }
        h1 { color: #22c55e; margin: 0 0 1rem; font-size: 1.5rem; }
        p { color: #666; margin: 0; }
        .icon { font-size: 4rem; margin-bottom: 1rem; }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">&#10004;</div>
        <h1>Authorization Successful</h1>
        <p>You can close this window and return to the terminal.</p>
    </div>
</body>
</html>"""
        self.wfile.write(html.encode())

    def send_error_page(self, message):
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Authorization Failed</title>
    <style>
        body {{ font-family: -apple-system, system-ui, sans-serif; display: flex;
               justify-content: center; align-items: center; height: 100vh; margin: 0;
               background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }}
        .card {{ background: white; padding: 3rem; border-radius: 1rem; text-align: center;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3); max-width: 400px; }}
        h1 {{ color: #ef4444; margin: 0 0 1rem; font-size: 1.5rem; }}
        p {{ color: #666; margin: 0; }}
        .icon {{ font-size: 4rem; margin-bottom: 1rem; }}
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">&#10008;</div>
        <h1>Authorization Failed</h1>
        <p>{message}</p>
    </div>
</body>
</html>"""
        self.wfile.write(html.encode())


class OAuthServer(socketserver.TCPServer):
    """TCP server with OAuth state."""
    allow_reuse_address = True
    oauth_code = None
    oauth_error = None
    expected_state = None


def exchange_code_for_token(token_url, code, client_id, client_secret, redirect_uri, extra_params=None, include_grant_type=True):
    """Exchange authorization code for access token."""
    data = {
        "code": code,
        "client_id": client_id,
        "client_secret": client_secret,
        "redirect_uri": redirect_uri,
    }
    if include_grant_type:
        data["grant_type"] = "authorization_code"
    if extra_params:
        data.update(extra_params)

    encoded = urllib.parse.urlencode(data).encode()

    req = urllib.request.Request(
        token_url,
        data=encoded,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode()
            print(f"Token exchange HTTP {e.code}: {body}", file=sys.stderr)
            return json.loads(body)
        except Exception:
            return {"error": f"HTTP {e.code}: {e.reason}"}
    except Exception as e:
        return {"error": str(e)}


def run_oauth_flow(oauth_config, client_id, client_secret):
    """
    Run complete OAuth flow.

    Args:
        oauth_config: dict with auth_url, token_url, and optional scopes
        client_id: OAuth client ID
        client_secret: OAuth client secret

    Returns:
        dict with tokens on success, or {"error": "message"} on failure
    """
    auth_url = oauth_config.get("auth_url")
    token_url = oauth_config.get("token_url")
    scopes = oauth_config.get("scopes", [])
    extra_auth_params = oauth_config.get("extra_auth_params", {})
    extra_token_params = oauth_config.get("extra_token_params", {})
    include_grant_type = not oauth_config.get("no_grant_type", False)

    if not auth_url or not token_url:
        return {"error": "Missing auth_url or token_url in OAuth config"}

    port = find_free_port()
    redirect_uri = f"http://localhost:{port}/callback"
    state = secrets.token_urlsafe(32)

    # Build authorization URL
    params = {
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "state": state,
    }
    if scopes:
        params["scope"] = " ".join(scopes) if isinstance(scopes, list) else scopes
    params.update(extra_auth_params)

    full_auth_url = f"{auth_url}?{urllib.parse.urlencode(params)}"

    # Start callback server
    server = OAuthServer(("localhost", port), OAuthCallbackHandler)
    server.expected_state = state

    print(f"Opening browser for authorization...", file=sys.stderr)
    print(f"If the browser doesn't open, visit: {full_auth_url}", file=sys.stderr)
    print(file=sys.stderr)

    open_browser(full_auth_url)

    # Wait for callback (with timeout)
    server.timeout = 300  # 5 minutes
    server.handle_request()

    if server.oauth_error:
        return {"error": server.oauth_error}

    if not server.oauth_code:
        return {"error": "No authorization code received"}

    # Exchange code for token
    print("Exchanging code for access token...", file=sys.stderr)

    token_response = exchange_code_for_token(
        token_url,
        server.oauth_code,
        client_id,
        client_secret,
        redirect_uri,
        extra_token_params,
        include_grant_type
    )

    return token_response


def main():
    """CLI interface for testing."""
    if len(sys.argv) < 2:
        print("Usage: oauth.py <skill_dir>")
        print("       oauth.py --test <auth_url> <token_url> <client_id> <client_secret>")
        sys.exit(1)

    if sys.argv[1] == "--test":
        if len(sys.argv) < 6:
            print("Usage: oauth.py --test <auth_url> <token_url> <client_id> <client_secret>")
            sys.exit(1)

        oauth_config = {
            "auth_url": sys.argv[2],
            "token_url": sys.argv[3],
        }
        result = run_oauth_flow(oauth_config, sys.argv[4], sys.argv[5])
        print(json.dumps(result, indent=2))
    else:
        skill_dir = Path(sys.argv[1])
        skill_json = skill_dir / "skill.json"

        if not skill_json.exists():
            print(f"Error: {skill_json} not found")
            sys.exit(1)

        with open(skill_json) as f:
            skill_data = json.load(f)

        oauth_config = skill_data.get("oauth")
        if not oauth_config:
            print("Error: No OAuth config in skill.json")
            sys.exit(1)

        # Read client credentials from env file or args
        env_file = skill_dir / ".env"
        client_id = None
        client_secret = None

        if env_file.exists():
            for line in env_file.read_text().splitlines():
                if "=" in line:
                    key, value = line.split("=", 1)
                    value = value.strip('"').strip("'")
                    if "CLIENT_ID" in key:
                        client_id = value
                    elif "CLIENT_SECRET" in key:
                        client_secret = value

        if not client_id or not client_secret:
            print("Error: CLIENT_ID and CLIENT_SECRET must be configured")
            sys.exit(1)

        result = run_oauth_flow(oauth_config, client_id, client_secret)
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
