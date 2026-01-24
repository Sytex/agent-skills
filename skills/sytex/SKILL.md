---
name: sytex
description: Connect to Sytex platform API. Use when user mentions Sytex, app, claro, ufinet, dt, adc, atis, exsei, integrar, torresec, or app_eu instances. Handles tasks, projects, forms, materials, organizations.
allowed-tools:
  - Read
  - Bash(~/.claude/skills/sytex/*:*)
---

# Sytex API Integration

Manage tasks, projects, sites, materials, forms, and automations via the Sytex API.

## Required Flags

Every command (except `find-org`) requires:

```bash
~/.claude/skills/sytex/sytex --base-url <URL> --org <ID> <command>
```

**Always ask user for confirmation before executing commands.**

### Finding the org

If user provides org name instead of ID, use `find-org` first:

```bash
~/.claude/skills/sytex/sytex find-org "Telecom Argentina"
```

**Instances**: app, app_eu, claro, ufinet, dt, adc, atis, exsei, integrar, torresec (all at `https://<name>.sytex.io`, except app_eu: `https://app.eu.sytex.io`)

## Commands

All commands: `~/.claude/skills/sytex/sytex --base-url <URL> --org <ID> <command>`

### Tasks
| Command | Description |
|---------|-------------|
| `tasks [flags]` | List tasks |
| `task <id>` | Get task details |
| `task-update <id> <json>` | Update task (PATCH) |
| `task-status <code> <status>` | Update status by code |
| `task-create <json>` | Create task |

### Projects & Sites
| Command | Description |
|---------|-------------|
| `projects [flags]` | List projects |
| `project <id>` | Get project details |
| `sites [flags]` | List sites |
| `site <id>` | Get site details |

### Materials
| Command | Description |
|---------|-------------|
| `materials [flags]` | List materials |
| `material-ops [flags]` | List material operations |
| `mo-status <code> <status>` | Update MO status |
| `mo-add-item <json>` | Add item to MO |

### Forms
| Command | Description |
|---------|-------------|
| `forms [flags]` | List form instances |
| `form <id>` | Get form details |

### Staff
| Command | Description |
|---------|-------------|
| `staff [flags]` | List staff members |
| `user-roles <name>` | Get roles for a user |

### Automations
| Command | Description |
|---------|-------------|
| `automation <uuid> [json]` | Execute automation |

### Task Templates

**Two types exist - ask user which one or search both:**

| Type | Command | Endpoint |
|------|---------|----------|
| Simple templates | `tasktemplates`, `tasktemplate <id>` | `/api/tasktemplate/` |
| Workflow tasks | `workstructure-tasks`, `workstructure-task <id>` | `/api/workstructuretask/` |

### Workstructures (Workflows)
| Command | Description |
|---------|-------------|
| `workstructures [flags]` | List workstructures |
| `workstructure <id>` | Get workstructure details |

### Custom Fields
| Command | Description |
|---------|-------------|
| `customfields --model MODEL --object-id ID` | Get custom fields |

Models: `workstructure`, `task`, `project`, `site`, `client`, `staff`, `form`, `materialoperation`

### Organizations
| Command | Requires | Description |
|---------|----------|-------------|
| `find-org <name>` | (none) | Search across ALL instances |
| `orgs [--q QUERY]` | `--base-url` only | List orgs in one instance |

### Generic Endpoints
| Command | Description |
|---------|-------------|
| `get <endpoint>` | GET any endpoint |
| `post <endpoint> [json]` | POST to any endpoint |
| `patch <endpoint> <json>` | PATCH any endpoint |
| `delete <endpoint>` | DELETE any endpoint |

## Common Flags

| Flag | Description |
|------|-------------|
| `--limit <n>` | Results per page |
| `--offset <n>` | Skip first N results |
| `--q <query>` | Search text |
| `--ordering <field>` | Sort (prefix `-` for desc) |

## Examples

```bash
# Find org across all instances
~/.claude/skills/sytex/sytex find-org "TMA"

# List tasks
~/.claude/skills/sytex/sytex --base-url https://app.sytex.io --org 141 tasks --limit 10

# Get task template (simple)
~/.claude/skills/sytex/sytex --base-url https://app.sytex.io --org 217 tasktemplate 1045

# Get workflow task template
~/.claude/skills/sytex/sytex --base-url https://app.sytex.io --org 217 workstructure-task 1045

# Execute automation
~/.claude/skills/sytex/sytex --base-url https://app.sytex.io --org 141 automation "uuid-here" '{"key": "value"}'
```
