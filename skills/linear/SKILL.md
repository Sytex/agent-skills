---
name: linear
description: Manage Linear issues, projects, and cycles. Use when user asks about issues, tasks, tickets, sprints, or Linear.
allowed-tools:
  - Read
  - Bash(~/.claude/skills/linear/*:*)
---

# Linear Integration

Manage issues, projects, and cycles in Linear.

## Commands

All commands: `~/.claude/skills/linear/linear <command>`

### Account & Teams
| Command | Description |
|---------|-------------|
| `me` | Get current user info |
| `teams` | List all teams |
| `team <id\|key>` | Get team details and workflow states |
| `states <team-key>` | List workflow states |

### Issues
| Command | Description |
|---------|-------------|
| `issues [flags]` | List issues |
| `issue <id\|identifier>` | Get issue details (e.g., ENG-123) |
| `issue-create <title> <team-key>` | Create issue |
| `issue-update <id> <field> <value>` | Update issue |
| `search <query> [limit]` | Search issues |
| `comment <issue-id> <body>` | Add comment |

**Issue flags:**
- `--limit <n>` - Max results (default: 25)
- `--team <key>` - Filter by team (e.g., ENG)
- `--me` - Assigned to me
- `--assignee <name>` - Filter by assignee
- `--state <name>` - Filter by state
- `--project <name>` - Filter by project

**Update fields:** `title`, `description`, `stateId`, `assigneeId`, `priority`

### Projects & Cycles
| Command | Description |
|---------|-------------|
| `projects [--limit n]` | List projects |
| `project <id>` | Get project details with issues |
| `cycles <team-key>` | List cycles for a team |

### Generic
| Command | Description |
|---------|-------------|
| `query <graphql>` | Run raw GraphQL query |

## Examples

```bash
# My issues
~/.claude/skills/linear/linear issues --me

# Issues in a team
~/.claude/skills/linear/linear issues --team ENG --state "In Progress"

# Get issue by identifier
~/.claude/skills/linear/linear issue ENG-123

# Create issue
~/.claude/skills/linear/linear issue-create "Fix login bug" ENG

# Search
~/.claude/skills/linear/linear search "login bug" 10

# Add comment
~/.claude/skills/linear/linear comment <issue-id> "Fixed in latest commit"
```
