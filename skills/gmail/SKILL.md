---
name: gmail
description: Read and search Gmail messages. Use when user wants to check email, search inbox, or read messages. Supports multiple Gmail accounts.
allowed-tools: Read, Bash(~/.claude/skills/gmail/*:*)
---

# Gmail Integration

Connect to Gmail via IMAP to read, search, and browse emails. Supports multiple Gmail accounts.

## Commands

All commands use the script: `~/.claude/skills/gmail/gmail`

### Global Flags
| Flag | Description |
|------|-------------|
| `--account <name>` or `-a <name>` | Select account (default: first configured) |

### Setup
| Command | Description |
|---------|-------------|
| `accounts` | List configured accounts |

### Profile & Folders

| Command | Description |
|---------|-------------|
| `me` | Get account info (email, message counts) |
| `labels` | List all folders/labels |

### Messages

| Command | Description |
|---------|-------------|
| `list [flags]` | List messages from inbox |
| `get <messageId>` | Read full message content |
| `search <query> [flags]` | Search messages |

### List Flags

| Flag | Description |
|------|-------------|
| `--label <folder>` | Folder name (INBOX, [Gmail]/Sent Mail, etc) |
| `--limit <n>` | Max results (default: 10) |
| `--unread` | Only unread messages |

### Search Flags

| Flag | Description |
|------|-------------|
| `--limit <n>` | Max results (default: 10) |
| `--oldest` | Show oldest messages first (default: newest first) |
| `--all` | Search in All Mail (includes archived emails) |
| `--trash` | Search in Trash |
| `--label <folder>` | Search in specific folder |

## Usage Examples

### List configured accounts
```bash
~/.claude/skills/gmail/gmail accounts
```

### Check inbox (default account)
```bash
~/.claude/skills/gmail/gmail list --limit 5
```

### Check inbox from specific account
```bash
~/.claude/skills/gmail/gmail --account work list --limit 5
~/.claude/skills/gmail/gmail --account personal list --unread
```

### Check unread messages
```bash
~/.claude/skills/gmail/gmail list --unread
```

### Read a specific email
```bash
~/.claude/skills/gmail/gmail get 12345
```

### Search for emails from someone
```bash
~/.claude/skills/gmail/gmail search "from:boss@company.com"
```

### Search from specific account
```bash
~/.claude/skills/gmail/gmail --account work search "from:client@company.com"
```

### Search by subject
```bash
~/.claude/skills/gmail/gmail search "subject:invoice"
```

### Search unread
```bash
~/.claude/skills/gmail/gmail search "is:unread"
```

### Search old emails (oldest first)
```bash
~/.claude/skills/gmail/gmail search older_than:1y --oldest --limit 20
```

### Search including archived emails
```bash
~/.claude/skills/gmail/gmail search "from:boss@company.com" --all
```

### Search by date range
```bash
~/.claude/skills/gmail/gmail search "from:client@company.com before:2023/06/01"
```

### List all folders
```bash
~/.claude/skills/gmail/gmail labels
```

## Search Syntax

| Query | Description |
|-------|-------------|
| `from:email@example.com` | From specific sender |
| `to:email@example.com` | To specific recipient |
| `subject:meeting` | Subject contains word |
| `is:unread` | Unread messages |
| `is:starred` | Starred messages |
| `before:2024/01/15` | Before date (YYYY/MM/DD or YYYY-MM-DD) |
| `after:2024/01/15` | After date |
| `older_than:7d` | Older than N days/months/years (d/m/y) |
| `newer_than:1m` | Newer than N days/months/years |
| `<text>` | Search in body |

Multiple terms can be combined: `from:boss@company.com older_than:6m`

## When to Use

Activate this skill when user:
- Asks to check their email or inbox
- Wants to search for specific emails
- Needs to read an email's content
- Asks about unread messages
- Wants to find emails from someone
- Needs to browse their email folders
- Mentions a specific Gmail account (work, personal, etc.)

## Notes

- This skill is read-only (no sending, deleting, or modifying emails)
