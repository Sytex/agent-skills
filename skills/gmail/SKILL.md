---
name: gmail
description: Read and search Gmail messages. Use when user wants to check email, search inbox, or read messages.
allowed-tools: Read, Bash(~/.claude/skills/gmail/*:*)
---

# Gmail Integration

## Purpose

Connect to Gmail via IMAP to read, search, and browse emails in the user's inbox.

## Setup Required

Before first use, the user must configure an App Password. This is a one-time setup.

### 1. Enable 2FA (if not already enabled)

Go to https://myaccount.google.com/security and enable 2-Step Verification.

### 2. Create an App Password

1. Go to https://myaccount.google.com/apppasswords
2. Select app: **Mail**
3. Select device: **Other** (enter "Gmail CLI")
4. Click **Generate**
5. Copy the 16-character password (no spaces)

### 3. Configure

```bash
~/.claude/skills/gmail/config.sh setup
```

Enter your Gmail address and App Password when prompted.

### 4. Verify Setup

```bash
~/.claude/skills/gmail/gmail me
```

## Available Commands

All commands use the script: `~/.claude/skills/gmail/gmail`

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
| `search <query> [limit]` | Search messages |

### List Flags

| Flag | Description |
|------|-------------|
| `--label <folder>` | Folder name (INBOX, [Gmail]/Sent Mail, etc) |
| `--limit <n>` | Max results (default: 10) |
| `--unread` | Only unread messages |

## Usage Examples

### Check inbox
```bash
~/.claude/skills/gmail/gmail list --limit 5
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

### Search by subject
```bash
~/.claude/skills/gmail/gmail search "subject:invoice"
```

### Search unread
```bash
~/.claude/skills/gmail/gmail search "is:unread"
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
| `<text>` | Search in body |

## When to Use

Activate this skill when user:
- Asks to check their email or inbox
- Wants to search for specific emails
- Needs to read an email's content
- Asks about unread messages
- Wants to find emails from someone
- Needs to browse their email folders

## Notes

- This skill is read-only (no sending, deleting, or modifying emails)
- Credentials stored securely in `~/.claude/skills/gmail/.env` with restricted permissions (chmod 600)
- App Passwords can be revoked anytime at https://myaccount.google.com/apppasswords
