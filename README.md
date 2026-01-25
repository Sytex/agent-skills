# Agent Skills

Skills for AI coding agents by the Sytex team.

## Available Skills

| Skill                                       | Description                                                 |
| ------------------------------------------- | ----------------------------------------------------------- |
| [gmail](./skills/gmail)                     | Read Gmail messages via IMAP                                |
| [issue-resolution](./skills/issue-resolution) | End-to-end workflow for resolving user-reported problems  |
| [linear](./skills/linear)                   | Manage issues and projects                                  |
| [sentry](./skills/sentry)                   | Monitor errors and issues                                   |
| [slite](./skills/slite)                     | Connect with Slite knowledge base                           |
| [sytex](./skills/sytex)                     | Interact with Sytex production API                          |

## Installation

### Using the Installer

**Terminal (interactive):**
```bash
./installer/install.sh
```

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

### Option 2: Tell your agent

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
