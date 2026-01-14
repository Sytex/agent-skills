---
name: sytex
description: Interact with Sytex API - manage tasks, projects, sites, materials, forms and automations. Use when user wants to work with Sytex data.
allowed-tools: Read, Bash(~/.claude/skills/sytex/*:*)
---

# Sytex API Integration

## Purpose

Connect to Sytex's production API to manage tasks, projects, sites, materials, forms, and execute automations.

## Setup Required

Before first use, configure your credentials.

### Getting your Token

Request your token from the development team.

Tokens expire after 30 days but auto-refresh on each use.

### Getting your Organization ID

Find it in the Sytex URL:
```
https://app.sytex.io/o/139/tasks
                      ^^^
                      Organization ID
```

### Configure

Run the setup:

```bash
~/.claude/skills/sytex/config.sh setup
```

Enter:
- **Token**: From dev team
- **Organization ID**: From URL
- **Base URL**: `https://app.sytex.io` (or custom instance)

## Available Commands

All commands use the script: `~/.claude/skills/sytex/sytex`

### Tasks

| Command | Description |
|---------|-------------|
| `tasks [flags]` | List tasks with optional filters |
| `task <id>` | Get task details |
| `task-update <id> <json>` | Update task fields (PATCH) |
| `task-status <code> <status>` | Update task status by code |
| `task-create <json>` | Create a new task |

### Projects

| Command | Description |
|---------|-------------|
| `projects [flags]` | List projects |
| `project <id>` | Get project details |

### Sites

| Command | Description |
|---------|-------------|
| `sites [flags]` | List sites |
| `site <id>` | Get site details |

### Materials

| Command | Description |
|---------|-------------|
| `materials [flags]` | List materials |
| `material-ops [flags]` | List material operations (MO) |
| `mo-status <code> <status>` | Update MO status |
| `mo-add-item <json>` | Add item to a material operation |

### Forms

| Command | Description |
|---------|-------------|
| `forms [flags]` | List forms |
| `form <id>` | Get form details |

### Staff

| Command | Description |
|---------|-------------|
| `staff [flags]` | List staff members |
| `user-roles <name>` | Get all roles for a user by name |

### Automations

| Command | Description |
|---------|-------------|
| `automation <uuid> [json]` | Execute an automation by UUID |

### Generic Endpoints

| Command | Description |
|---------|-------------|
| `get <endpoint>` | GET any endpoint |
| `post <endpoint> [json]` | POST to any endpoint |
| `put <endpoint> <json>` | PUT to any endpoint |
| `patch <endpoint> <json>` | PATCH any endpoint |
| `delete <endpoint>` | DELETE any endpoint |

### Common Flags

| Flag | Description |
|------|-------------|
| `--limit <n>` | Results per page |
| `--offset <n>` | Skip first N results |
| `--q <query>` | Search text |
| `--status <id>` | Filter by status ID |
| `--ordering <field>` | Sort by field (prefix - for desc) |

## Usage Examples

### List tasks
```bash
~/.claude/skills/sytex/sytex tasks --limit 10
```

### Search tasks by name
```bash
~/.claude/skills/sytex/sytex tasks --q "maintenance"
```

### Get task details
```bash
~/.claude/skills/sytex/sytex task 12345
```

### Update task status
```bash
~/.claude/skills/sytex/sytex task-status "TASK-001" "En proceso"
```

### Create a task
```bash
~/.claude/skills/sytex/sytex task-create '{"name": "New Task", "project": 1}'
```

### List sites
```bash
~/.claude/skills/sytex/sytex sites --limit 20 --q "tower"
```

### Update material operation status
```bash
~/.claude/skills/sytex/sytex mo-status "MO-M1-23-59835" "Confirmada"
```

### Add item to material operation
```bash
~/.claude/skills/sytex/sytex mo-add-item '{
  "operation": "MO-R1-23-2186",
  "material": "10000405",
  "quantity": 1,
  "item_number": 1,
  "source_location": "1015",
  "source_location_type": "Deposito virtual",
  "destination_location": "1015",
  "destination_location_type": "Deposito virtual"
}'
```

### Execute an automation
```bash
~/.claude/skills/sytex/sytex automation "a08e40f4-d8a8-4ab0-8ad4-82afbcba2fe3" '{"latitude": -31.34, "longitude": -64.24}'
```

### Get user roles
```bash
~/.claude/skills/sytex/sytex user-roles "Camilo Parra"
```

### Generic GET request
```bash
~/.claude/skills/sytex/sytex get "/user/"
```

### Generic POST request
```bash
~/.claude/skills/sytex/sytex post "/formstart/" '{"form_template": 123}'
```

## Response Handling

All responses are JSON. Parse with `jq` when needed:

```bash
~/.claude/skills/sytex/sytex tasks --limit 5 | jq '.results[].name'
~/.claude/skills/sytex/sytex task 123 | jq '{id, name, status: .status.name}'
```

## API Response Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 204 | Deleted |
| 400 | Validation error (check response body for details) |
| 401 | Invalid or expired token |
| 403 | Permission denied |
| 404 | Resource not found |

## Pagination

List endpoints return paginated results:

```json
{
  "count": 150,
  "next": "/api/task/?limit=25&offset=25",
  "previous": null,
  "results": [...]
}
```

Use `--offset` to navigate pages:
```bash
~/.claude/skills/sytex/sytex tasks --limit 25 --offset 50
```

## Common Tasks

### Get user roles
Use `user-roles <name>` to get all roles assigned to a user:
```bash
~/.claude/skills/sytex/sytex user-roles "Camilo Parra"
```

### Get staff details
Use `staff --q <name>` to search staff, then `get /staff/<id>/` for full details.

## When to Use

Activate this skill when user:
- Asks to list, search, or manage tasks in Sytex
- Wants to update task or operation statuses
- Needs to query projects, sites, or materials
- Wants to execute automations
- **Asks about user roles or permissions**
- Needs to interact with any Sytex API endpoint

## Notes

- Token authentication is used (simpler setup)
- All requests include the Organization header automatically
- Status updates use the import endpoints for reliability
- Use generic commands (get, post, etc.) for unlisted endpoints
- The `status_step` field in status updates must match the exact status name in Sytex
