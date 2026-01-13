# Slite CLI

CLI to connect any AI agent (Claude Code, Codex, Cursor, etc.) with your Slite knowledge base.

## Installation

Tell your agent:

> "Install the Slite skill from this repo"

Or manually:

```bash
cd skills/slite
./install.sh
```

## Configuration

After installing, configure your API key:

```bash
~/.claude/skills/slite/config.sh setup
```

Or tell your agent:
> "Run the Slite setup, I'll provide my API key"

### Getting your API Key

1. Log in to your Slite workspace
2. Click your avatar (bottom left corner)
3. Go to **Settings → API**
4. Click **Generate new token**
5. Copy the key (only shown once)

## Usage

### With any AI agent

Ask your agent things like:

- "Search Slite for onboarding documentation"
- "Show me the structure of the Engineering section"
- "Ask Slite how we handle deployments"
- "Create a note in Slite with this meeting summary"

### Direct commands

```bash
~/.claude/skills/slite/slite search "onboarding"
~/.claude/skills/slite/slite search "deploy" --parent abc123 --depth 2
~/.claude/skills/slite/slite tree abc123
~/.claude/skills/slite/slite ask "How do we deploy?" --parent abc123
~/.claude/skills/slite/slite get <noteId>
```

## Available Commands

### Read

| Command | Description |
|---------|-------------|
| `me` | User info |
| `search <query> [flags]` | Search notes |
| `ask <question> [--parent id]` | Ask AI |
| `list [parentId]` | List notes |
| `get <noteId> [md\|html]` | Get note |
| `children <noteId>` | Direct child notes |
| `tree <noteId> [depth]` | Hierarchy tree |
| `search-users <query>` | Search users |

### Search Flags

| Flag | Description |
|------|-------------|
| `--parent <id>` | Search within a parent note |
| `--depth <n>` | Depth (1-3) |
| `--include-archived` | Include archived |
| `--after <date>` | Edited after (ISO) |
| `--limit <n>` | Results per page |

### Write

| Command | Description |
|---------|-------------|
| `create <title> [md] [parent]` | Create note |
| `update <noteId> [title] [md]` | Update note |
| `delete <noteId>` | Delete note |
| `archive <noteId> [bool]` | Archive |
| `verify <noteId> [until]` | Verify |
| `outdated <noteId> <reason>` | Mark outdated |

## Best Practices

### Exploring the knowledge base
1. Use `list` to see top-level notes
2. Use `tree <noteId>` to see a section's structure
3. Use `get <noteId>` to read content

### Finding information
| Need | Command |
|------|---------|
| Search keyword | `search "keyword"` |
| Search in section | `search "keyword" --parent <id>` |
| AI answer | `ask "question"` |
| Scoped AI answer | `ask "question" --parent <id>` |
| View structure | `tree <id>` |

### Recommended flow
```
list → tree → search/ask → get
```

1. **list**: See what sections exist
2. **tree**: Explore a section's structure
3. **search/ask**: Find specific information
4. **get**: Read the full content

## File Structure

```
~/.claude/skills/slite/
├── slite        # Main CLI
├── config.sh    # API key configuration
├── .env         # API key (don't share!)
└── SKILL.md     # Claude Code skill definition
```
