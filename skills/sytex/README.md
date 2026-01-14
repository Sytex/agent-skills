# Sytex API Skill

CLI skill for interacting with the Sytex production API.

## Features

- Task management (list, create, update, status changes)
- Project and site queries
- Material and material operation management
- Form queries
- Automation execution
- Generic endpoint access for any API endpoint

## Installation

```bash
./install.sh
```

## Configuration

After installation, configure your credentials:

```bash
~/.claude/skills/sytex/config.sh setup
```

### How to get your credentials

**Token** - Request from the development team

**Organization ID** - From Sytex URL: `https://app.sytex.io/o/139/tasks` → `139`

**Base URL** - Usually `https://app.sytex.io`

## Quick Start

```bash
# List tasks
~/.claude/skills/sytex/sytex tasks --limit 10

# Get task details
~/.claude/skills/sytex/sytex task 12345

# Update task status
~/.claude/skills/sytex/sytex task-status "TASK-001" "Completada"

# List sites
~/.claude/skills/sytex/sytex sites --q "tower"

# Execute automation
~/.claude/skills/sytex/sytex automation "uuid-here" '{"key": "value"}'
```

## Documentation

See [SKILL.md](SKILL.md) for full documentation.

## Requirements

- bash
- curl
- python3 (for URL encoding)
- jq (optional, for parsing responses)
