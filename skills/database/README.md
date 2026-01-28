# Database Skill

Read-only MySQL/MariaDB client for querying databases. Supports multiple database connections (production, staging, local, etc.).

## What it does

This skill provides safe, read-only access to databases, allowing AI coding agents to:

- Query production, staging, or local databases
- Switch between different database environments
- Compare data across environments
- Explore database schema and relationships
- Generate reports and statistics
- Validate data integrity
- Debug API behavior by checking database state

## Safety Features

- **Read-only access**: Only SELECT queries are allowed
- **Query validation**: All queries are checked before execution
- **No modifications**: Cannot INSERT, UPDATE, DELETE, or alter data
- **Separate credentials**: Uses dedicated read-only database user per connection
- **Multiple databases**: Configure as many database connections as needed

## Prerequisites

- MySQL client (`mysql`) must be installed
  - macOS: `brew install mysql-client`
  - Linux: `apt-get install mysql-client` or `yum install mysql`
- Database user with SELECT-only permissions

## Installation

Use the installer to set up this skill:

```bash
./installer/install.sh database install
```

Or via web UI:
```bash
./installer/install.sh --web
```

## Configuration

You can configure multiple database connections. For each connection, you'll need:

- **Connection Name**: A short identifier (e.g., "production", "staging", "local")
- **Host**: Database server hostname or IP
- **Port**: Database port (default: 3306)
- **Database**: Name of the database
- **User**: Read-only database username
- **Password**: Password for the database user

The installer allows you to add multiple databases. Each connection is independent and can point to different servers or environments.

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

Once installed, the agent can use the `database` command:

### List Databases
```bash
database dbs                 # List all configured databases
```

### Test Connection
```bash
database test                # Test default database
database --db production test   # Test specific database
```

### Explore Database
```bash
database tables                     # List all tables (default DB)
database --db staging tables        # List tables in staging
database describe tasks             # Show table schema
database stats                      # Database statistics
```

### Query Data
```bash
# Query default database
database query "SELECT * FROM tasks WHERE status = 'open' LIMIT 10"

# Query specific database
database --db production query "SELECT COUNT(*) FROM users" json
database --db staging query "SELECT * FROM tasks WHERE id = 123"
```

### Compare Across Environments
```bash
# Compare record counts
database --db production query "SELECT COUNT(*) FROM projects_task"
database --db staging query "SELECT COUNT(*) FROM projects_task"

# Check schema differences
database --db production describe projects_task
database --db staging describe projects_task
```

## Available Commands

| Command | Description |
|---------|-------------|
| `dbs` | List all configured database connections with status |
| `test` | Test database connection |
| `tables` | List all tables |
| `describe <table>` | Show table schema and indexes |
| `query <sql> [format]` | Execute SELECT query (formats: table, json, csv) |
| `stats` | Show database statistics |
| `help` | Show help message |

**Global Options:**
- `--db <name>`: Select a specific database connection (if not specified, uses default)

## Output Formats

- **table** (default): Human-readable table format
- **json**: JSON array for parsing
- **csv**: Comma-separated values

## Examples

**Investigate a specific task:**
```bash
database query "SELECT * FROM tasks WHERE id = 12345"
```

**Find open tasks in a project:**
```bash
database query "
SELECT t.id, t.title, t.status, t.assigned_to
FROM tasks t
WHERE t.project_id = 100 AND t.status = 'open'
LIMIT 20
"
```

**Count tasks by status:**
```bash
database query "SELECT status, COUNT(*) as count FROM tasks GROUP BY status"
```

**Export data as JSON:**
```bash
database query "SELECT id, name, email FROM users LIMIT 10" json
```

**Working with multiple databases:**
```bash
# List all configured databases
database dbs

# Compare data between production and staging
database --db production query "SELECT COUNT(*) FROM projects_task WHERE status_id = 5"
database --db staging query "SELECT COUNT(*) FROM projects_task WHERE status_id = 5"

# Debug by comparing the same record in different environments
database --db production query "SELECT * FROM projects_task WHERE id = 47515"
database --db staging query "SELECT * FROM projects_task WHERE id = 47515"

# Test a query in staging before running in production
database --db staging query "SELECT * FROM new_feature_table LIMIT 5"
# If successful, run in production:
database --db production query "SELECT * FROM new_feature_table LIMIT 5"
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
- Test with: `database test`

### "mysql client not found"
Install MySQL client:
- macOS: `brew install mysql-client`
- Linux: `apt-get install mysql-client`

### Query errors
- Use `database tables` to see available tables
- Use `database describe <table>` to see columns
- Check SQL syntax
- Ensure query is SELECT-only

## Support

For issues or feature requests, please contact the Sytex team.
