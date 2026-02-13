# Agent Skills

Skills for AI coding agents by the Sytex team.

## Available Skills

| Skill                                       | Description                                                 |
| ------------------------------------------- | ----------------------------------------------------------- |
| [gmail](./skills/gmail)                     | Read Gmail messages via IMAP                                |
| [issue-resolution](./skills/issue-resolution) | End-to-end workflow for resolving user-reported problems  |
| [linear](./skills/linear)                   | Manage issues and projects                                  |
| [pipedrive](./skills/pipedrive)             | Manage deals, contacts, and sales pipeline                  |
| [sentry](./skills/sentry)                   | Monitor errors and issues                                   |
| [slite](./skills/slite)                     | Connect with Slite knowledge base                           |
| [sytex](./skills/sytex)                     | Interact with Sytex production API                          |
| [database](./skills/database)               | Read-only MySQL/MariaDB client for querying databases       |

## Supported Providers

Skills can be installed to multiple AI coding agents simultaneously:

| Provider | Install Path |
| -------- | ------------ |
| Claude Code | `~/.claude/skills/<skill>/` |
| Codex CLI | `~/.codex/skills/<skill>/` |
| Gemini CLI | `~/.gemini/skills/<skill>/` |

The installer stores your provider configuration in `~/.agent-skills/config.json`.

## Installation

### Option 1: Desktop App (macOS)

Download the `.dmg` from [GitHub Releases](https://github.com/pablanka/agent-skills/releases) and drag to Applications. The app bundles skills and auto-updates via GitHub Releases.

### Option 2: CLI / Web UI

**Terminal (interactive):**
```bash
./installer/install.sh
```

On first run, you'll be prompted to select which providers to use. Skills are installed to all enabled providers.

**Web UI:**
```bash
./installer/install.sh --web
```

**Direct install:**
```bash
./installer/install.sh <skill-name>
./installer/install.sh sentry install
./installer/install.sh sentry test
```

### Option 3: Tell your agent

> "Install the Slite skill from this repo"

## Structure

```
agent-skills/
├── README.md
├── installer/
│   ├── install.sh      # Entry point
│   ├── cli.sh          # CLI logic (bash + gum)
│   ├── web.py          # Web server (Python stdlib)
│   ├── templates/
│   │   └── index.html  # Web UI
│   └── bin/            # gum binary (auto-downloaded)
├── desktop/            # macOS desktop app (Tauri v2)
│   ├── src-tauri/      # Rust backend
│   └── dist/           # Loading screen
└── skills/
    ├── sentry/
    │   ├── skill.json  # Metadata + form fields
    │   ├── SKILL.md
    │   └── ...
    └── linear/
        └── ...
```

## Adding a new skill

1. Create folder at `skills/<name>/`
2. Include `skill.json` with metadata and form fields
3. Include `README.md` with documentation
4. Include `SKILL.md` for the agent

## Guidelines

**Skills must be agent-agnostic.** Do not reference specific AI agents (Claude, Codex, Gemini, ChatGPT, Cursor, etc.) in documentation or code. Write for "AI coding agents" generically.

The installation path is determined by the target agent, not the skill itself.
