# Agent Skills

## Desktop App (Tauri v2)

The macOS desktop app lives in `desktop/`. It wraps the existing web UI (`installer/web.py`) compiled into a standalone binary via PyInstaller, served inside a Tauri WebView.

### Build

```bash
cd desktop
./scripts/build-server.sh   # Compile web.py → bin/agent-skills-server (PyInstaller)
npx tauri build              # Package into .app and .dmg
./scripts/fix-dmg.sh         # Clean DMG (remove .VolumeIcon.icns, .fseventsd)
```

### Releasing a new version

The app auto-updates via GitHub Releases. To release:

1. Bump the version in `desktop/src-tauri/tauri.conf.json` (`"version"` field)
2. Bump the version in `desktop/package.json` (`"version"` field)
3. Commit and tag: `git tag v0.2.0 && git push --tags`
4. GitHub Actions builds for both Apple Silicon and Intel, creates a draft Release
5. Review the draft Release on GitHub and publish it
6. Users get the update automatically next time they open the app

Version format: `v{major}.{minor}.{patch}` (e.g., `v0.1.0`, `v0.2.0`, `v1.0.0`)

### Signing (required for auto-update)

Before the first release, set up these GitHub secrets:

- `TAURI_SIGNING_PRIVATE_KEY` — generate with `npx tauri signer generate`
- `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` — password for the signing key
- `APPLE_CERTIFICATE` — base64-encoded .p12 certificate
- `APPLE_CERTIFICATE_PASSWORD` — certificate password
- `APPLE_SIGNING_IDENTITY` — e.g., "Developer ID Application: Your Name (TEAMID)"
- `APPLE_ID` — Apple Developer email
- `APPLE_PASSWORD` — app-specific password
- `APPLE_TEAM_ID` — Apple Developer Team ID

Add the public key from `npx tauri signer generate` to `desktop/src-tauri/tauri.conf.json` → `plugins.updater.pubkey`.

### Architecture

```
Tauri app → spawns bin/agent-skills-server (PyInstaller binary) → WebView shows localhost:{port}
```

- No Python required on user's system — interpreter is bundled in the binary
- Skills are bundled inside the .app — updating the app updates skills
- Git operations are disabled in bundled mode (`BUNDLED_MODE=1`)
- `installer/web.py` supports `--no-browser`, `SKILLS_DIR`, `INSTALLER_DIR`, and `BUNDLED_MODE` env vars for the desktop app without affecting CLI/web modes
