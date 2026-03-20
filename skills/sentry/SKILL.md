---
name: sentry
description: Monitor errors and issues from Sentry. Supports multiple organizations. Use when user asks about errors, exceptions, issues, or wants to check Sentry.
allowed-tools:
  - Read
  - Bash(~/.claude/skills/sentry/*:*)
---

# Sentry Integration (Multi-org)

Monitor and manage errors, issues, and events from multiple Sentry organizations.

## Multi-Organization Support

This skill supports multiple Sentry organizations. Use `--org <slug>` to specify which organization to query.

```bash
# List all configured organizations
~/.claude/skills/sentry/sentry orgs

# Query a specific organization
~/.claude/skills/sentry/sentry --org sytex-eu issues
```

## Commands

All commands: `~/.claude/skills/sentry/sentry [--org <slug>] <command>`

### Organizations
| Command | Description |
|---------|-------------|
| `orgs` | List all configured organizations with connection status |

### Projects
| Command | Description |
|---------|-------------|
| `projects` | List all projects |
| `project <slug>` | Get project details |

### Issues
| Command | Description |
|---------|-------------|
| `issues [flags]` | List issues |
| `issue <id>` | Get issue details |

**Issue flags:**
- `--project <slug>` - Filter by project
- `--query <search>` - Sentry search syntax
- `--status <status>` - unresolved, resolved, ignored
- `--env <name>` - Filter by environment
- `--sort <field>` - date, freq, new, user
- `--limit <n>` - Max results (max 100)

### Events
| Command | Description |
|---------|-------------|
| `events <issue_id> [--full]` | List events for an issue |
| `event <project> <event_id>` | Get full event with stacktrace |

### Actions
| Command | Description |
|---------|-------------|
| `resolve <issue_id>` | Mark as resolved |
| `unresolve <issue_id>` | Reopen issue |
| `ignore <issue_id> [mins]` | Ignore (optionally for N minutes) |
| `assign <issue_id> <user>` | Assign to user |

### Stats
| Command | Description |
|---------|-------------|
| `stats [--stat type] [--period 24h]` | Org stats (received, rejected) |

## Search Query Syntax

| Query | Description |
|-------|-------------|
| `is:unresolved` | Unresolved issues |
| `is:resolved` | Resolved issues |
| `is:ignored` | Ignored issues |
| `is:assigned` | Assigned to someone |
| `assigned:me` | Assigned to me |
| `level:error` | Error level |
| `environment:production` | By environment |
| `release:1.0.0` | By release |

## Examples

```bash
# List all configured organizations
~/.claude/skills/sentry/sentry orgs

# List unresolved issues (uses default org)
~/.claude/skills/sentry/sentry issues --status unresolved --limit 10

# List issues from a specific org
~/.claude/skills/sentry/sentry --org sytex-eu issues --status unresolved

# Get issue details
~/.claude/skills/sentry/sentry issue 12345678

# Get events with full stacktrace
~/.claude/skills/sentry/sentry events 12345678 --full

# Resolve an issue
~/.claude/skills/sentry/sentry resolve 12345678

# Search by environment
~/.claude/skills/sentry/sentry issues --query "environment:production level:error"
```

## Configuration

The skill stores organization credentials in `~/.claude/skills/sentry/.env` with the format:

```
SENTRY_ORG_<SLUG>_TOKEN="..."
SENTRY_ORG_<SLUG>_URL="https://sentry.io"
SENTRY_DEFAULT_ORG="sytex"
```

Run the installer to add or modify organizations.
