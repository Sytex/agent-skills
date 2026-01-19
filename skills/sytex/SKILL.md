---
name: sytex
description: Connect to app.sytex.io platform API. Use when user mentions Sytex platform, wants to query/create tasks, projects, forms, materials, or switch organizations. Note: "Sytex" refers to the platform, not an OperationalUnit.
allowed-tools: Read, Bash(~/.claude/skills/sytex/*:*)
---

# Sytex API Integration

Manage tasks, projects, sites, materials, forms, and automations via the Sytex API.

## Setup

Run `~/.claude/skills/sytex/config.sh setup` and provide:
- **Token**: Request from dev team (expires after 30 days, auto-refreshes on use)
- **Organization ID**: From URL `https://app.sytex.io/o/139/tasks` (139 is the ID)
- **Base URL**: `https://app.sytex.io` (or custom instance)

## Key Concepts

- **Organization**: The tenant/company account (ID in URL: `/o/139/`). Configured via `config.sh org`.
- **OperationalUnit**: A work area WITHIN an organization. Used when creating FormTemplates, assigning tasks, etc.

These are NOT the same. Organization is the top-level account, OperationalUnit is a subdivision inside it.

## Configuration

Every API call shows the active organization in stderr: `[Sytex] Organization: 139`

| Command | Description |
|---------|-------------|
| `~/.claude/skills/sytex/config.sh org` | Show current organization |
| `~/.claude/skills/sytex/config.sh org <id>` | Switch to organization |
| `~/.claude/skills/sytex/config.sh subdomain` | Show current subdomain |
| `~/.claude/skills/sytex/config.sh subdomain <name>` | Switch subdomain (app, claro, ufinet, etc.) |

**Always check the active organization and subdomain before making changes.**

## Commands

All commands use: `~/.claude/skills/sytex/sytex <command>`

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

**Note**: Forms are instances created from FormTemplates. To create or manage FormTemplates, see [FORM_TEMPLATES.md](FORM_TEMPLATES.md).

### Staff
| Command | Description |
|---------|-------------|
| `staff [flags]` | List staff members |
| `user-roles <name>` | Get roles for a user |

### Automations
| Command | Description |
|---------|-------------|
| `automation <uuid> [json]` | Execute automation |

### Workstructures (Workflows)
| Command | Description |
|---------|-------------|
| `workstructures [flags]` | List workstructures |
| `workstructure <id>` | Get workstructure details |
| `workstructure-tasks [flags]` | List workstructure task templates |
| `workstructure-task <id>` | Get workstructure task template details |

**Note**: In the API, "workstructure" = "workflow" in the UI. A workstructure and its associated project share the same code (e.g., `ARG-004927207`).

### Custom Fields
| Command | Description |
|---------|-------------|
| `customfields --model MODEL --object-id ID` | Get custom fields for any entity |

**Available models**: `workstructure`, `task`, `project`, `site`, `client`, `staff`, `form`, `materialoperation`

**Important distinctions**:
- `workstructuretask`: Task *templates* defined in a workflow structure
- `task`: Actual task *instances* created from templates (these have custom field values)

To get custom fields of tasks in a workflow:
1. Find the workstructure: `workstructures --code ARG-004927207`
2. Get its project ID from the response
3. List tasks: `tasks --project <project_id>`
4. Get custom fields: `customfields --model task --object-id <task_id>`

### Generic Endpoints
| Command | Description |
|---------|-------------|
| `get <endpoint>` | GET any endpoint |
| `post <endpoint> [json]` | POST to any endpoint |
| `put <endpoint> <json>` | PUT to any endpoint |
| `patch <endpoint> <json>` | PATCH any endpoint |
| `delete <endpoint>` | DELETE any endpoint |

## Common Flags

| Flag | Description |
|------|-------------|
| `--limit <n>` | Results per page |
| `--offset <n>` | Skip first N results |
| `--q <query>` | Search text |
| `--status <id>` | Filter by status ID |
| `--ordering <field>` | Sort (prefix `-` for desc) |

## Examples

```bash
# Check/switch organization and subdomain
~/.claude/skills/sytex/config.sh org
~/.claude/skills/sytex/config.sh org 142
~/.claude/skills/sytex/config.sh subdomain
~/.claude/skills/sytex/config.sh subdomain claro

# List tasks
~/.claude/skills/sytex/sytex tasks --limit 10 --q "maintenance"

# Update task status
~/.claude/skills/sytex/sytex task-status "TASK-001" "En proceso"

# Create task
~/.claude/skills/sytex/sytex task-create '{"name": "New Task", "project": 1}'

# Execute automation
~/.claude/skills/sytex/sytex automation "a08e40f4-..." '{"latitude": -31.34}'

# Get user roles
~/.claude/skills/sytex/sytex user-roles "<user_name>"

# Find workflow by code
~/.claude/skills/sytex/sytex workstructures --code ARG-004927207

# Get custom fields of a workflow
~/.claude/skills/sytex/sytex customfields --model workstructure --object-id 272608

# Get custom fields of a task
~/.claude/skills/sytex/sytex customfields --model task --object-id 3520400
```

## Response Format

All responses are JSON. Paginated results:
```json
{"count": 150, "next": "...", "previous": null, "results": [...]}
```

## API Response Codes

| Code | Meaning |
|------|---------|
| 200/201 | Success |
| 400 | Validation error |
| 401 | Invalid/expired token |
| 403 | Permission denied |
| 404 | Not found |
