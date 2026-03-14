---
name: send-message
description: >-
  Use this skill ONLY when the agent itself needs to post a message to a Discord channel
  as part of an automated task or scheduled job — to report results, send alerts, or notify
  a channel. Do NOT use this when the agent is already responding in an active conversation;
  the response IS the message. Only use it when explicitly instructed to send to a specific channel ID.
version: 3.0.0
allowed-tools:
  - Bash(~/.claude/skills/send-message/*:*)
---

# Send Message

Send and edit Discord messages via Kadmos API.

## Usage

```bash
~/.claude/skills/send-message/kadmos-send --channel-id <ID> --content "Your message here"
```

## Options

- `--channel-id` (required): Discord channel ID
- `--content`: Message content (required unless `--file` is used)
- `--file`: Read message content from a file (for large messages)
- `--edit <message_id>`: Edit an existing message instead of sending a new one

## Mentions

To mention users or roles, include Discord mention syntax directly in the content:
- Users: `<@USER_ID>` (e.g., `<@710519366801686550>`)
- Roles: `<@&ROLE_ID>` (e.g., `<@&123456789>`)

The scheduled task context provides mention targets — use them in `--content` where appropriate.

## Large Messages

Messages longer than 2000 characters are automatically split into multiple messages. For large content, prefer `--file` over `--content` to avoid shell argument limits.

## Examples

```bash
# Simple message
~/.claude/skills/send-message/kadmos-send \
  --channel-id 123456789 \
  --content "Daily report: All systems healthy."

# Message with mention
~/.claude/skills/send-message/kadmos-send \
  --channel-id 123456789 \
  --content "<@111222333> Alert: CPU usage above 90%"

# Large message from file
~/.claude/skills/send-message/kadmos-send \
  --channel-id 123456789 \
  --file /tmp/report.md

# Edit an existing message
~/.claude/skills/send-message/kadmos-send \
  --channel-id 123456789 \
  --edit 987654321 \
  --content "Updated: All systems healthy."
```

## Guidelines

- Keep messages concise and informative
- Use mentions sparingly, only when the user needs to be notified
- Do NOT send a message if there is nothing noteworthy to report
- If you decide not to send a message, simply complete your task silently
- For large reports, write content to a temp file first and use `--file`
- Editing a message replaces its content entirely (truncates at 2000 chars)
