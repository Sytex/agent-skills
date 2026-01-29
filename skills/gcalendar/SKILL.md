---
name: gcalendar
description: Manage Google Calendar events. Use when user asks about calendar, events, meetings, appointments, or schedule.
allowed-tools:
  - Read
  - Bash(~/.claude/skills/gcalendar/*:*)
---

# Google Calendar Integration

Manage events, calendars, and schedule via Google Calendar API.

## Commands

All commands: `~/.claude/skills/gcalendar/gcalendar <command>`

### Setup
| Command | Description |
|---------|-------------|
| `auth` | Setup OAuth2 authentication |
| `status` | Check authentication status |

### Calendars
| Command | Description |
|---------|-------------|
| `calendars` | List all calendars |
| `calendar [id]` | Get calendar details (default: primary) |

### Events
| Command | Description |
|---------|-------------|
| `events [flags]` | List events |
| `event <id>` | Get event details |
| `event-create <title> [flags]` | Create event |
| `event-delete <id>` | Delete event |
| `quick <text>` | Quick add with natural language |

**Event list flags:**
- `--calendar <id>` - Calendar ID (default: primary)
- `--limit <n>` - Max results (default: 10)
- `--from <datetime>` - Start time (ISO format)
- `--to <datetime>` - End time (ISO format)
- `--today` - Show today's events
- `--week` - Show next 7 days
- `--query <text>` - Search in events

**Event create flags:**
- `--calendar <id>` - Calendar ID
- `--date <YYYY-MM-DD>` - All-day event
- `--start <HH:MM>` - Start time
- `--end <HH:MM>` - End time
- `--start-date <YYYY-MM-DD>` - Start date (multi-day)
- `--end-date <YYYY-MM-DD>` - End date
- `--description <text>` - Description
- `--location <text>` - Location

## Examples

```bash
# List today's events
~/.claude/skills/gcalendar/gcalendar events --today

# List next 7 days
~/.claude/skills/gcalendar/gcalendar events --week

# Search events
~/.claude/skills/gcalendar/gcalendar events --query "meeting"

# Create all-day event
~/.claude/skills/gcalendar/gcalendar event-create "Vacation" --date 2026-02-15

# Create timed event
~/.claude/skills/gcalendar/gcalendar event-create "Call with client" --start 14:00 --end 15:00

# Quick add (natural language)
~/.claude/skills/gcalendar/gcalendar quick "Lunch with John tomorrow at noon"

# Delete event
~/.claude/skills/gcalendar/gcalendar event-delete <event-id>
```

## When to Use

Activate this skill when user:
- Asks about their calendar or schedule
- Wants to see upcoming events or meetings
- Needs to create, modify, or delete events
- Asks "what do I have today/tomorrow/this week"
- Wants to schedule something
