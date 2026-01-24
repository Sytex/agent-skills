---
name: sytex
description: Connect to app.sytex.io platform API. Use when user mentions Sytex platform, wants to query/create tasks, projects, forms, materials, or switch organizations. Note: "Sytex" refers to the platform, not an OperationalUnit.
allowed-tools: Read, Bash(~/.claude/skills/sytex/*:*)
---

# Sytex API Integration

Manage tasks, projects, sites, materials, forms, and automations via the Sytex API.

## CRITICAL: Confirmation Required

**ALWAYS ask the user for confirmation before executing ANY Sytex command.**

Before running a command, present a brief summary:
- What action will be performed (GET, POST, PATCH, DELETE)
- Which organization and base URL will be used
- What data will be sent (if applicable)

Example:
> "I'm about to list tasks from **org 141** on **app.sytex.io** with limit 10. Proceed?"

**Never execute without explicit user approval.**

## CRITICAL: Organization Resolution

**Both `--base-url` and `--org` are MANDATORY.** If the user doesn't provide both, you MUST resolve them before executing.

### Sytex Instances

| Instance | URL | Type |
|----------|-----|------|
| app | https://app.sytex.io | Multi-tenant (many orgs) |
| app_eu | https://app.eu.sytex.io | Multi-tenant EU (many orgs) |
| claro | https://claro.sytex.io | Dedicated (1 org) |
| ufinet | https://ufinet.sytex.io | Dedicated (1 org) |
| dt | https://dt.sytex.io | Dedicated (1 org) |
| adc | https://adc.sytex.io | Dedicated (1 org) |
| alfred | https://alfred.sytex.io | Dedicated (1 org) |
| atis | https://atis.sytex.io | Dedicated (1 org) |
| exsei | https://exsei.sytex.io | Dedicated (1 org) |
| integrar | https://integrar.sytex.io | Dedicated (1 org) |
| torresec | https://torresec.sytex.io | Dedicated (1 org) |

### Resolution Flow

**If user provides org NAME (not ID):**
1. Run `find-org "<name>"` to search across ALL instances
2. If multiple matches found, ask user to clarify
3. Use the returned `base_url` and `org_id`

**If user provides only org ID:**
1. Run `find-org` or `orgs --q <id>` on likely instances to find it
2. Once found, use that instance's base_url

**If user provides only instance name:**
1. Run `orgs` on that instance to list organizations
2. Ask user which org to use

**If user provides NEITHER:**
1. ASK the user for org name or ID before proceeding
2. Never assume defaults when user context suggests a specific org

### Discovery Commands

```bash
# Search org by name across ALL instances (no flags needed)
~/.claude/skills/sytex/sytex find-org "Telecom Argentina"

# List orgs in a specific instance (only --base-url needed)
~/.claude/skills/sytex/sytex --base-url https://app.sytex.io orgs --q "telecom"
```

## Setup

Run `~/.claude/skills/sytex/config.sh setup` and provide:
- **Token**: Request from dev team (expires after 30 days, auto-refreshes on use)

That's it. The token is the only persisted configuration.

## Required Flags

**Every command (except `find-org`) requires both flags:**

```bash
~/.claude/skills/sytex/sytex --base-url <URL> --org <ID> <command>
```

Example:
```bash
~/.claude/skills/sytex/sytex --base-url https://app.sytex.io --org 141 tasks --limit 10
```

**Nothing is persisted. You must specify both on every call.**

## Key Concepts

- **Organization**: The tenant/company account (ID in URL: `/o/139/`). Default: 141.
- **OperationalUnit**: A work area WITHIN an organization. Used when creating FormTemplates, assigning tasks, etc.

These are NOT the same. Organization is the top-level account, OperationalUnit is a subdivision inside it.

## Commands

All commands use: `~/.claude/skills/sytex/sytex --base-url <URL> --org <ID> <command>`

### Global Flags (REQUIRED for all commands except find-org)
| Flag | Description |
|------|-------------|
| `--base-url <url>` | Instance URL (e.g., https://app.sytex.io) |
| `--org <id>` | Organization ID |

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

### Organizations (Discovery - different flag requirements)
| Command | Requires | Description |
|---------|----------|-------------|
| `find-org <name>` | (none) | Search org by name across ALL instances |
| `orgs [--q QUERY]` | `--base-url` only | List organizations in specified instance |

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
# DISCOVERY: Find org by name across all instances (no flags needed)
~/.claude/skills/sytex/sytex find-org "Telecom Argentina"

# DISCOVERY: List orgs in a specific instance (only --base-url needed)
~/.claude/skills/sytex/sytex --base-url https://app.sytex.io orgs --q "telecom"

# List tasks (--base-url and --org are REQUIRED)
~/.claude/skills/sytex/sytex --base-url https://app.sytex.io --org 141 tasks --limit 10 --q "maintenance"

# Use dedicated instance
~/.claude/skills/sytex/sytex --base-url https://claro.sytex.io --org 1 tasks

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
