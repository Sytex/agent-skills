# Sentry Skill

CLI tool to interact with Sentry API for error monitoring.

## Installation

```bash
./install.sh
```

## Configuration

```bash
~/.claude/skills/sentry/config.sh setup
```

You'll need:
- **Auth Token**: Settings > Auth Tokens in Sentry
- **Organization slug**: Your org identifier

## Usage

```bash
# List projects
~/.claude/skills/sentry/sentry projects

# List unresolved issues
~/.claude/skills/sentry/sentry issues --status unresolved

# Get issue details
~/.claude/skills/sentry/sentry issue <issue_id>

# Get events with stacktrace
~/.claude/skills/sentry/sentry events <issue_id> --full

# Resolve issue
~/.claude/skills/sentry/sentry resolve <issue_id>
```

## Token Permissions

Required scopes:
- `project:read` - List projects
- `event:read` - Read issues and events
- `event:write` - Resolve/ignore issues
