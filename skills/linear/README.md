# Linear Skill

CLI tool to interact with Linear API for issue tracking.

## Installation

```bash
./install.sh
```

## Configuration

```bash
~/.claude/skills/linear/config.sh setup
```

You'll need your API key from: Settings > Security & access > Personal API keys

## Usage

```bash
# Get my info
~/.claude/skills/linear/linear me

# List my issues
~/.claude/skills/linear/linear issues --me

# Get issue details
~/.claude/skills/linear/linear issue ENG-123

# Create issue
~/.claude/skills/linear/linear issue-create "Bug title" TEAM-KEY

# Search issues
~/.claude/skills/linear/linear search "keyword"
```

## API

Linear uses GraphQL. The `query` command allows raw GraphQL queries:

```bash
~/.claude/skills/linear/linear query "{ viewer { id name } }"
```
