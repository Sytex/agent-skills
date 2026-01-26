---
name: pipedrive
description: Manage deals, contacts, organizations, and activities in Pipedrive CRM. Use when user asks about deals, sales, contacts, pipeline, or Pipedrive.
allowed-tools:
  - Read
  - Bash(~/.claude/skills/pipedrive/*:*)
---

# Pipedrive Integration

Manage deals, contacts, organizations, and activities in Pipedrive CRM.

## Commands

All commands: `~/.claude/skills/pipedrive/pipedrive <command>`

### Setup
| Command | Description |
|---------|-------------|
| `auth` | Setup OAuth2 authentication |
| `status` | Check authentication status |

### Account
| Command | Description |
|---------|-------------|
| `me` | Get current user info |
| `users` | List all users |

### Deals
| Command | Description |
|---------|-------------|
| `deals [flags]` | List deals |
| `deal <id>` | Get deal details |
| `deal-create <title> [flags]` | Create deal |
| `deal-update <id> <field> <value>` | Update deal |
| `deal-delete <id>` | Delete deal |

**Deal flags:**
- `--limit <n>` - Max results (default: 50)
- `--status <open\|won\|lost\|all>` - Filter by status (default: open)
- `--pipeline <id>` - Filter by pipeline
- `--stage <id>` - Filter by stage
- `--user <id>` - Filter by owner
- `--org <id>` - Filter by organization
- `--person <id>` - Filter by person

**Create flags:**
- `--org <id>` - Link to organization
- `--person <id>` - Link to person
- `--pipeline <id>` - Pipeline ID
- `--stage <id>` - Stage ID
- `--value <amount>` - Deal value
- `--currency <code>` - Currency (e.g., USD, EUR)

**Update fields:** `title`, `value`, `currency`, `status`, `stage_id`, `pipeline_id`, `person_id`, `org_id`, `expected_close_date`

### Persons (Contacts)
| Command | Description |
|---------|-------------|
| `persons [flags]` | List persons |
| `person <id>` | Get person details |
| `person-create <name> [flags]` | Create person |
| `person-update <id> <field> <value>` | Update person |
| `person-delete <id>` | Delete person |

**Person flags:**
- `--limit <n>` - Max results (default: 50)
- `--org <id>` - Filter by organization

**Create flags:**
- `--email <email>` - Email address
- `--phone <phone>` - Phone number
- `--org <id>` - Link to organization

**Update fields:** `name`, `email`, `phone`, `org_id`

### Organizations
| Command | Description |
|---------|-------------|
| `orgs [--limit n]` | List organizations |
| `org <id>` | Get organization details |
| `org-create <name>` | Create organization |
| `org-update <id> <field> <value>` | Update organization |
| `org-delete <id>` | Delete organization |

**Update fields:** `name`, `address`

### Activities
| Command | Description |
|---------|-------------|
| `activities [flags]` | List activities |
| `activity <id>` | Get activity details |
| `activity-create <type> <subject> [flags]` | Create activity |
| `activity-done <id>` | Mark activity as done |
| `activity-delete <id>` | Delete activity |

**Activity flags:**
- `--limit <n>` - Max results (default: 50)
- `--type <type>` - Filter by type (call, meeting, task, deadline, email, lunch)
- `--done <0\|1>` - Filter by done status
- `--user <id>` - Filter by user
- `--deal <id>` - Filter by deal
- `--person <id>` - Filter by person

**Create flags:**
- `--deal <id>` - Link to deal
- `--person <id>` - Link to person
- `--org <id>` - Link to organization
- `--due <date>` - Due date (YYYY-MM-DD)
- `--time <time>` - Due time (HH:MM)
- `--duration <mins>` - Duration in minutes
- `--note <text>` - Activity note

### Pipelines & Stages
| Command | Description |
|---------|-------------|
| `pipelines` | List all pipelines |
| `pipeline <id>` | Get pipeline with stages |
| `stages <pipeline-id>` | List stages in a pipeline |

### Notes
| Command | Description |
|---------|-------------|
| `notes <entity> <id>` | List notes (entity: deal, person, org) |
| `note-create <entity> <id> <content>` | Add note to entity |

### Search
| Command | Description |
|---------|-------------|
| `search <query> [--type <type>]` | Search across Pipedrive |

**Search types:** `deal`, `person`, `organization`, `product`, `file`

## Examples

```bash
# My info
~/.claude/skills/pipedrive/pipedrive me

# List open deals
~/.claude/skills/pipedrive/pipedrive deals

# List won deals
~/.claude/skills/pipedrive/pipedrive deals --status won

# Get deal details
~/.claude/skills/pipedrive/pipedrive deal 123

# Create a deal
~/.claude/skills/pipedrive/pipedrive deal-create "New Project" --value 5000 --org 456

# Update deal value
~/.claude/skills/pipedrive/pipedrive deal-update 123 value 10000

# List contacts
~/.claude/skills/pipedrive/pipedrive persons --limit 20

# Create contact
~/.claude/skills/pipedrive/pipedrive person-create "John Doe" --email john@example.com --phone "+1234567890"

# List activities for today
~/.claude/skills/pipedrive/pipedrive activities --done 0

# Create a call activity
~/.claude/skills/pipedrive/pipedrive activity-create call "Follow up call" --deal 123 --due 2024-01-15

# Mark activity done
~/.claude/skills/pipedrive/pipedrive activity-done 789

# Search for deals
~/.claude/skills/pipedrive/pipedrive search "acme" --type deal

# Add note to deal
~/.claude/skills/pipedrive/pipedrive note-create deal 123 "Called and discussed pricing"
```
