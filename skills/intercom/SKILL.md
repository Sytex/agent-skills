---
name: intercom
description: Manage Intercom conversations, contacts, and tickets. Use when user mentions Intercom, conversations, soporte, chats, support tickets, or wants to investigate a user issue.
allowed-tools:
  - Bash(~/.claude/skills/intercom/*:*)
---

# Intercom

Access and manage Intercom conversations, contacts, and tickets.

## Support Investigation Workflow

When asked to investigate an issue or help with a support conversation:

### 1. Find conversations (flexible entry point)

```bash
# Latest conversations
intercom conversations

# By contact email
intercom conversations --email pepe@empresa.com

# By contact name
intercom conversations --name "Pepe García"

# Only open conversations
intercom conversations --open --limit 10

# Search by content/topic
intercom conversations-search "error de sincronización"
```

### 2. Read the full conversation

```bash
intercom conversation <id>
```

Returns all messages, notes, and metadata in plain text.

### 3. Cross-reference with Sytex (if relevant)

Use the `sytex` or `sytex-reports` skill to understand the technical context:
- Look up the org, tasks, or sites related to the user's issue
- Check recent task statuses, errors, or workflow states

### 4. Leave an internal note with suggested response

```bash
intercom conversation-note <id> "Suggested response: ..."
```

**Note vs Reply:**
- `conversation-note` → internal note, **only visible to the support team**
- `conversation-reply` → message sent to the user

---

## Commands

### Conversations

| Command | Description |
|---------|-------------|
| `conversations` | List recent conversations |
| `conversations --email <email>` | Conversations for a contact by email |
| `conversations --name <name>` | Conversations for a contact by name |
| `conversations --contact <id>` | Conversations for a contact by ID |
| `conversations --open\|--closed` | Filter by status |
| `conversations --limit <n>` | Max results (default: 20) |
| `conversation <id>` | Full conversation with all messages |
| `conversations-search <query>` | Search conversations by content |
| `conversation-note <id> <text>` | Add internal note (team only) |
| `conversation-reply <id> <text>` | Reply to user (visible to user) |
| `conversation-close <id>` | Close conversation |
| `conversation-open <id>` | Reopen conversation |

### Contacts

| Command | Description |
|---------|-------------|
| `contacts` | List contacts |
| `contacts --email <email>` | Search by email |
| `contact <id>` | Get contact details |
| `search <query>` | Search contacts by name or email |
| `contact-create <email>` | Create contact |
| `contact-update <id> <field> <value>` | Update contact field |
| `contact-delete <id>` | Delete contact |

### Companies

| Command | Description |
|---------|-------------|
| `companies` | List companies |
| `company <id>` | Get company details |
| `company-create <name>` | Create company |

### Tickets

| Command | Description |
|---------|-------------|
| `tickets` | List tickets |
| `ticket <id>` | Get ticket details |
| `ticket-types` | List available ticket types |
| `ticket-create <type_id> <title>` | Create ticket |
| `ticket-update <id>` | Update ticket (`--close`, `--open`, `--state <id>`) |

### Admins & Tags

| Command | Description |
|---------|-------------|
| `admins` | List workspace admins |
| `admin <id>` | Get admin details |
| `tags` | List tags |
| `tag-contact <contact_id> <tag_id>` | Tag a contact |

---

## Examples

```bash
# Find conversations for a user and read the latest one
intercom conversations --email pepe@empresa.com
intercom conversation 12345

# Search for similar cases
intercom conversations-search "formulario no carga"

# Leave internal note with suggested response
intercom conversation-note 12345 "Sugerencia: el problema es X. Responder con Y."

# Reply to the user (only when ready)
intercom conversation-reply 12345 "Hola! Investigamos el problema y..."
```
