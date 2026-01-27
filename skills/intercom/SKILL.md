# Intercom

Manage contacts, conversations, and tickets in Intercom.

## Commands

### Authentication
- `intercom status` - Check authentication status
- `intercom me` - Get current admin info

### Contacts
- `intercom contacts` - List contacts
- `intercom contacts --email user@example.com` - Search by email
- `intercom contact <id>` - Get contact details
- `intercom contact-create <email>` - Create contact
  - `--name <name>` - Contact name
  - `--phone <phone>` - Phone number
  - `--role <user|lead>` - Contact role
- `intercom contact-update <id> <field> <value>` - Update contact
- `intercom contact-delete <id>` - Delete contact

### Conversations
- `intercom conversations` - List all conversations
- `intercom conversations --open` - List open conversations
- `intercom conversations --closed` - List closed conversations
- `intercom conversation <id>` - Get conversation details
- `intercom conversation-reply <id> "<message>"` - Reply to conversation
- `intercom conversation-close <id>` - Close conversation
- `intercom conversation-open <id>` - Reopen conversation

### Companies
- `intercom companies` - List companies
- `intercom company <id>` - Get company details
- `intercom company-create <name>` - Create company
  - `--id <company_id>` - Custom company ID

### Tickets
- `intercom tickets` - List tickets
- `intercom ticket <id>` - Get ticket details
- `intercom ticket-types` - List available ticket types
- `intercom ticket-create <type_id> <title>` - Create ticket
  - `--contact <id>` - Link to contact
  - `--description <text>` - Ticket description
- `intercom ticket-update <id>` - Update ticket
  - `--close` - Close ticket
  - `--open` - Reopen ticket
  - `--state <state_id>` - Set ticket state

### Admins
- `intercom admins` - List workspace admins
- `intercom admin <id>` - Get admin details

### Tags
- `intercom tags` - List tags
- `intercom tag-contact <contact_id> <tag_id>` - Tag a contact

### Search
- `intercom search <query>` - Search contacts by name or email

## Examples

```bash
# Check connection status
intercom status

# List open conversations
intercom conversations --open

# Reply to a conversation
intercom conversation-reply 12345 "Thanks for reaching out!"

# Create a new contact
intercom contact-create user@example.com --name "John Doe" --role user

# Search for contacts
intercom search "john"

# Create a ticket
intercom ticket-create 1 "Bug report" --description "Found an issue"
```
