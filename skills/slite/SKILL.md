---
name: slite
description: Interact with Slite knowledge base - search, read, create, and manage notes. Use when user wants to work with Slite documents.
allowed-tools: Read, Bash(~/.slite/*:*)
---

# Slite Integration

## Purpose

Connect to Slite's API to search, read, create, update, and manage notes in the user's knowledge base.

## Setup Required

Before first use, the user must configure their API key. Guide them with these steps:

### Cómo obtener tu API key de Slite

1. Abrí tu workspace de Slite en el navegador
2. Hacé click en tu avatar/foto de perfil (esquina inferior izquierda)
3. Seleccioná **Settings** (o Configuración)
4. En el menú lateral, buscá **API** (puede estar en "Integrations" o al final)
5. Hacé click en **Generate new token** o **Create API key**
6. Copiá la key generada (solo se muestra una vez)

### Configurar la API key

Una vez que el usuario tenga la key, ejecutar:

```bash
~/.slite/config.sh setup
```

El usuario debe pegar su API key cuando se le solicite.

## Available Commands

All commands use the script: `~/.slite/slite`

### Read Operations

| Command | Description |
|---------|-------------|
| `me` | Get current user info |
| `search <query> [flags]` | Search notes with optional filters |
| `ask <question> [--parent <id>]` | Ask AI a question (optionally scoped) |
| `list [parentId]` | List notes (optionally under a parent) |
| `get <noteId> [md\|html]` | Get note content |
| `children <noteId>` | Get direct child notes |
| `tree <noteId> [depth]` | Show note hierarchy tree (default depth: 3) |
| `search-users <query>` | Search users by name/email |

### Search Flags

| Flag | Description |
|------|-------------|
| `--parent <id>` | Filter results within a parent note |
| `--depth <n>` | Search depth (1-3) |
| `--include-archived` | Include archived notes in results |
| `--after <date>` | Notes edited after date (ISO format) |
| `--page <n>` | Page number for pagination |
| `--limit <n>` | Results per page |

### Write Operations

| Command | Description |
|---------|-------------|
| `create <title> [markdown] [parentId]` | Create a new note |
| `update <noteId> [title] [markdown]` | Update note content |
| `delete <noteId>` | Delete note (irreversible!) |
| `archive <noteId> [true\|false]` | Archive or unarchive |
| `verify <noteId> [until]` | Mark as verified |
| `outdated <noteId> <reason>` | Flag as outdated |

## Usage Examples

### Search for notes
```bash
~/.slite/slite search "onboarding"
```

### Search within a specific section
```bash
~/.slite/slite search "deploy" --parent abc123 --depth 2
```

### Explore note hierarchy
```bash
~/.slite/slite tree abc123
```

### Ask a question scoped to a section
```bash
~/.slite/slite ask "How do we handle deployments?" --parent abc123
```

### Get a specific note in markdown
```bash
~/.slite/slite get abc123 md
```

### Create a new note
```bash
~/.slite/slite create "Meeting Notes" "## Attendees\n- Alice\n- Bob"
```

### Update a note
```bash
~/.slite/slite update abc123 "New Title" "Updated content here"
```

### Search for a user
```bash
~/.slite/slite search-users "juan"
```

## Response Handling

All responses are JSON. Parse with `jq` when needed:

```bash
~/.slite/slite search "docs" | jq '.hits[].title'
~/.slite/slite tree abc123  # Already formatted as tree
```

## Best Practices

### Exploring the knowledge base
1. Start with `list` to see top-level notes
2. Use `tree <noteId>` to explore a section's structure
3. Use `get <noteId>` to read specific content

### Finding information
- **Broad search**: `search "keyword"` - finds notes across workspace
- **Scoped search**: `search "keyword" --parent <id>` - within a section
- **AI answer**: `ask "question"` - gets AI-synthesized answer with sources
- **Scoped AI**: `ask "question" --parent <id>` - answer from specific section

### When to use each command
| Need | Command |
|------|---------|
| Browse structure | `tree` |
| Find by keyword | `search` |
| Get AI answer | `ask` |
| Read full content | `get` |

## When to Use

Activate this skill when user:
- Asks to search, find, or look up something in Slite
- Wants to explore the knowledge base structure
- Wants to create or update documentation
- Needs to read content from their knowledge base
- Asks questions that should be answered from Slite
- Wants to manage notes (archive, verify, flag outdated)

## Notes

- The `ask` command uses Slite's AI to answer questions from the knowledge base
- Use `--parent` flag to scope searches and questions to specific sections
- `tree` is useful for understanding document structure before searching
- Delete is irreversible - always confirm with user first
- Note IDs can be found in search results, tree output, or note URLs
