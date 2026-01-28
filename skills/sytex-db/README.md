# Sytex Database Skill

Read-only MySQL/MariaDB client for querying the Sytex production database.

## What it does

This skill provides safe, read-only access to the Sytex database, allowing AI coding agents to:

- Query production data to investigate issues
- Explore database schema and relationships
- Generate reports and statistics
- Validate data integrity
- Debug API behavior by checking database state

## Safety Features

- **Read-only access**: Only SELECT queries are allowed
- **Query validation**: All queries are checked before execution
- **No modifications**: Cannot INSERT, UPDATE, DELETE, or alter data
- **Separate credentials**: Uses dedicated read-only database user

## Prerequisites

- MySQL client (`mysql`) must be installed
  - macOS: `brew install mysql-client`
  - Linux: `apt-get install mysql-client` or `yum install mysql`
- Database user with SELECT-only permissions

## Installation

Use the installer to set up this skill:

```bash
./installer/install.sh sytex-db install
```

Or via web UI:
```bash
./installer/install.sh --web
```

## Configuration

You'll need the following database credentials:

- **Host**: Database server hostname or IP
- **Port**: Database port (default: 3306)
- **Database**: Name of the database
- **User**: Read-only database username
- **Password**: Password for the database user

### Creating a Read-Only Database User

For safety, create a dedicated read-only user:

```sql
-- Create read-only user
CREATE USER 'readonly'@'%' IDENTIFIED BY 'secure_password';

-- Grant SELECT permission on the database
GRANT SELECT ON sytex_db.* TO 'readonly'@'%';

-- Apply changes
FLUSH PRIVILEGES;
```

## Usage

Once installed, the agent can use the `sytex-db` command:

### Test Connection
```bash
sytex-db test
```

### Explore Database
```bash
sytex-db tables              # List all tables
sytex-db describe tasks      # Show table schema
sytex-db stats               # Database statistics
```

### Query Data
```bash
sytex-db query "SELECT * FROM tasks WHERE status = 'open' LIMIT 10"
sytex-db query "SELECT COUNT(*) FROM users" json
```

### Predefined Queries
```bash
sytex-db tasks 20       # Recent tasks
sytex-db projects 10    # Recent projects
sytex-db users 50       # List users
```

## Available Commands

| Command | Description |
|---------|-------------|
| `test` | Test database connection |
| `tables` | List all tables |
| `describe <table>` | Show table schema and indexes |
| `query <sql> [format]` | Execute SELECT query (formats: table, json, csv) |
| `tasks [limit]` | Show recent tasks |
| `projects [limit]` | Show recent projects |
| `users [limit]` | Show users |
| `stats` | Show database statistics |
| `help` | Show help message |

## Output Formats

- **table** (default): Human-readable table format
- **json**: JSON array for parsing
- **csv**: Comma-separated values

## Examples

**Investigate a specific task:**
```bash
sytex-db query "SELECT * FROM tasks WHERE id = 12345"
```

**Find open tasks in a project:**
```bash
sytex-db query "
SELECT t.id, t.title, t.status, t.assigned_to
FROM tasks t
WHERE t.project_id = 100 AND t.status = 'open'
LIMIT 20
"
```

**Count tasks by status:**
```bash
sytex-db query "SELECT status, COUNT(*) as count FROM tasks GROUP BY status"
```

**Export data as JSON:**
```bash
sytex-db query "SELECT id, name, email FROM users LIMIT 10" json
```

## Security

- Uses read-only database credentials
- All queries validated to prevent modifications
- Credentials stored in `.env` (not committed to git)
- Production data treated as confidential

## Troubleshooting

### Connection fails
- Verify credentials in `.env` file
- Check database host is accessible
- Ensure database user has SELECT permissions
- Test with: `sytex-db test`

### "mysql client not found"
Install MySQL client:
- macOS: `brew install mysql-client`
- Linux: `apt-get install mysql-client`

### Query errors
- Use `sytex-db tables` to see available tables
- Use `sytex-db describe <table>` to see columns
- Check SQL syntax
- Ensure query is SELECT-only

## Support

For issues or feature requests, please contact the Sytex team.
