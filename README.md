# Agent Skills

Skills for AI coding agents by the Sytex team.

## Available Skills

| Skill                     | Description                        |
| ------------------------- | ---------------------------------- |
| [slite](./skills/slite)   | Connect with Slite knowledge base  |
| [gmail](./skills/gmail)   | Read Gmail messages via IMAP       |
| [sytex](./skills/sytex)   | Interact with Sytex production API |
| [sentry](./skills/sentry) | Monitor errors and issues          |
| [linear](./skills/linear) | Manage issues and projects         |

## Installation

### Option 1: Tell your agent

> "Install the Slite skill from this repo"

### Option 2: Manual

```bash
cd skills/<skill-name>
./install.sh
```

## Structure

```
agent-skills/
├── README.md
└── skills/
    ├── slite/
    │   ├── install.sh
    │   ├── README.md
    │   └── SKILL.md
    ├── gmail/
    │   ├── install.sh
    │   ├── README.md
    │   └── SKILL.md
    └── sytex/
        ├── install.sh
        ├── README.md
        └── SKILL.md
```

## Adding a new skill

1. Create folder at `skills/<name>/`
2. Include `install.sh` for installation
3. Include `README.md` with documentation
4. Include `SKILL.md` for the agent

## Guidelines

**Skills must be agent-agnostic.** Do not reference specific AI agents (Claude, Codex, Gemini, ChatGPT, Cursor, etc.) in documentation or code. Write for "AI coding agents" generically.

The installation path is determined by the target agent, not the skill itself.
