# Gmail Skill

Read and search Gmail messages using IMAP with App Passwords. Supports multiple accounts.

## Features

- List inbox messages with filters
- Search emails by sender, subject, or content
- Read full email content
- Browse folders/labels
- Multiple Gmail accounts support
- Works with any AI coding agent

## Requirements

- macOS or Linux with bash
- Python 3
- Google account with 2FA enabled

## Installation

```bash
cd skills/gmail
./install.sh
```

This installs to `~/.claude/skills/gmail/`.

## Setup

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

### 4. Test

```bash
~/.claude/skills/gmail/gmail me
```

## Multi-Account Setup

To add multiple Gmail accounts, edit `~/.claude/skills/gmail/.env`:

```bash
# Account: work
GMAIL_ACCOUNT_WORK_EMAIL="work@company.com"
GMAIL_ACCOUNT_WORK_APP_PASSWORD="xxxx xxxx xxxx xxxx"

# Account: personal
GMAIL_ACCOUNT_PERSONAL_EMAIL="personal@gmail.com"
GMAIL_ACCOUNT_PERSONAL_APP_PASSWORD="yyyy yyyy yyyy yyyy"

# Optional: set default account
GMAIL_DEFAULT_ACCOUNT="work"
```

Then use with `--account` or `-a` flag:

```bash
~/.claude/skills/gmail/gmail --account work list --unread
~/.claude/skills/gmail/gmail -a personal search "from:friend@gmail.com"
```

## Usage

### Commands

```bash
# List accounts
~/.claude/skills/gmail/gmail accounts

# Profile
~/.claude/skills/gmail/gmail me                     # Account info
~/.claude/skills/gmail/gmail labels                 # List folders

# Messages
~/.claude/skills/gmail/gmail list                   # List inbox (10 messages)
~/.claude/skills/gmail/gmail list --limit 5         # Limit results
~/.claude/skills/gmail/gmail list --unread          # Unread only
~/.claude/skills/gmail/gmail list --label "[Gmail]/Sent Mail"  # Sent folder
~/.claude/skills/gmail/gmail get <messageId>        # Read message
~/.claude/skills/gmail/gmail search "query"         # Search messages

# With specific account
~/.claude/skills/gmail/gmail --account work list --unread
~/.claude/skills/gmail/gmail -a personal search "from:friend@gmail.com"
```

### Search Examples

```bash
# From specific sender
~/.claude/skills/gmail/gmail search "from:boss@company.com"

# Subject contains keyword
~/.claude/skills/gmail/gmail search "subject:invoice"

# Unread messages
~/.claude/skills/gmail/gmail search "is:unread"

# Starred messages
~/.claude/skills/gmail/gmail search "is:starred"

# Text in body
~/.claude/skills/gmail/gmail search "meeting agenda"
```

### Search Syntax

| Query | Description |
|-------|-------------|
| `from:email` | From sender |
| `to:email` | To recipient |
| `subject:word` | Subject contains |
| `is:unread` | Unread messages |
| `is:starred` | Starred messages |
| `<text>` | Search in body |

## Agent Integration

After installation, use with your AI agent:

```
/gmail
```

Or ask naturally:
- "Check my unread emails"
- "Check my work email inbox"
- "Search for emails from john@example.com in my personal account"
- "Read the email about the meeting"

## Files

```
~/.claude/skills/gmail/
├── .env          # Credentials (chmod 600)
├── gmail         # Main script
├── config.sh     # Configuration
└── SKILL.md      # Skill definition
```

## Security

- Credentials stored with `chmod 600` (owner read/write only)
- App Passwords can be revoked at any time from Google settings
- This skill is read-only - cannot send, delete, or modify emails

## Troubleshooting

### "Login failed"
- Verify your email and App Password are correct
- Make sure 2FA is enabled on your Google account
- Try creating a new App Password

### "Connection refused"
- Check your internet connection
- Gmail IMAP might be temporarily unavailable

## License

MIT
