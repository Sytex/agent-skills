# Google Calendar Skill

Manage Google Calendar events via OAuth2.

## Features

- List calendars and events
- Create events (all-day or timed)
- Quick add with natural language
- Search events
- Delete events

## Requirements

- macOS or Linux with bash
- Python 3
- Google Cloud project with Calendar API enabled

## Installation

```bash
cd skills/gcalendar
./install.sh
```

This installs to `~/.claude/skills/gcalendar/`.

## Setup

### 1. Create Google Cloud Project

1. Go to https://console.cloud.google.com/
2. Create a new project (or select existing)
3. Enable **Google Calendar API**:
   - Go to APIs & Services > Library
   - Search "Google Calendar API"
   - Click Enable

### 2. Create OAuth Credentials

1. Go to APIs & Services > Credentials
2. Click **Create Credentials** > **OAuth client ID**
3. Application type: **Desktop app**
4. Name: "Calendar CLI" (or any name)
5. Click Create
6. Copy the **Client ID** and **Client Secret**

### 3. Configure

```bash
~/.claude/skills/gcalendar/gcalendar auth
```

Enter your Client ID and Client Secret when prompted. A browser window will open for Google authorization.

### 4. Test

```bash
~/.claude/skills/gcalendar/gcalendar events --today
```

## Usage

```bash
# List calendars
~/.claude/skills/gcalendar/gcalendar calendars

# Today's events
~/.claude/skills/gcalendar/gcalendar events --today

# Next 7 days
~/.claude/skills/gcalendar/gcalendar events --week

# Create event
~/.claude/skills/gcalendar/gcalendar event-create "Meeting" --start 14:00 --end 15:00

# Quick add (natural language)
~/.claude/skills/gcalendar/gcalendar quick "Dentist appointment Friday at 10am"

# Delete event
~/.claude/skills/gcalendar/gcalendar event-delete <event-id>
```

## Files

```
~/.claude/skills/gcalendar/
├── .env          # OAuth credentials (chmod 600)
├── gcalendar     # Main script
└── SKILL.md      # Skill definition
```

## Security

- Credentials stored with `chmod 600`
- OAuth tokens can be revoked from Google Account settings
- Only accesses calendars you authorize

## License

MIT
