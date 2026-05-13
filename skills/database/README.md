# Database Skill

Read-only MySQL/MariaDB client for querying databases. Supports multiple database connections and schemas.

## What it does

This skill provides safe, read-only access to databases, allowing AI coding agents to:

- Query configured database connections
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

- **Connection Name**: A short identifier for the configured connection
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

Once installed, the agent can use the bundled `database` executable.

Always assume the executable is not installed on `PATH`. Locate the database skill directory first, then run:

```bash
./database help
```

If your shell is not in the skill directory, use the absolute path to the skill's `database` executable. This can differ between Codex, Claude Code, and other shell-based agents. All command examples below use `./database` and assume the shell is already in the database skill directory.

### List Databases
```bash
./database dbs                 # List all configured databases
```

### Test Connection
```bash
./database test                # Test default database
./database --db <connection-name> test   # Test specific connection
```

### Explore Database
```bash
./database tables                                                # List all tables if a default schema is configured
./database --db <connection-name> --database <schema-name> tables # List tables in an explicit schema
./database --database <schema-name> describe tasks                # Show table schema
./database --database <schema-name> stats                         # Database statistics
```

### Query Data
```bash
# Query default database
./database query "SELECT * FROM tasks WHERE status = 'open' LIMIT 10"

# Query specific connection and schema
./database --db <connection-name> --database <schema-name> query "SELECT COUNT(*) FROM users" json
./database --db <connection-name> --database <schema-name> query "SELECT * FROM tasks WHERE id = 123"
```

### Compare Across Environments
```bash
# Compare record counts
./database --db <connection-a> --database <schema-name> query "SELECT COUNT(*) FROM projects_task"
./database --db <connection-b> --database <schema-name> query "SELECT COUNT(*) FROM projects_task"

# Check schema differences
./database --db <connection-a> --database <schema-name> describe projects_task
./database --db <connection-b> --database <schema-name> describe projects_task
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
- `--db <name>`: Select a specific configured connection (if not specified, uses default)
- `--database <name>`: Select the MySQL/MariaDB database/schema on that connection

## Output Formats

- **table** (default): Human-readable table format
- **json**: JSON array for parsing
- **csv**: Comma-separated values

Format is a positional argument after the SQL string, not a global flag:

```bash
./database --database <schema-name> query "SELECT COUNT(*) FROM users" json
```

Do not use `--json`. Some installed MySQL clients do not support JSON output; if `json` returns an error such as `unknown option '--json'`, rerun the query with default table output or `csv`.

## Examples

**Investigate a specific task:**
```bash
./database query "SELECT * FROM tasks WHERE id = 12345"
```

**Find open tasks in a project:**
```bash
./database query "
SELECT t.id, t.title, t.status, t.assigned_to
FROM tasks t
WHERE t.project_id = 100 AND t.status = 'open'
LIMIT 20
"
```

**Count tasks by status:**
```bash
./database query "SELECT status, COUNT(*) as count FROM tasks GROUP BY status"
```

**Export data as JSON:**
```bash
./database query "SELECT id, name, email FROM users LIMIT 10" json
```

**Working with multiple databases:**
```bash
# List all configured connections
./database dbs

# Compare data between two connections
./database --db <connection-a> --database <schema-name> query "SELECT COUNT(*) FROM projects_task WHERE status_id = 5"
./database --db <connection-b> --database <schema-name> query "SELECT COUNT(*) FROM projects_task WHERE status_id = 5"

# Debug by comparing the same record in different environments
./database --db <connection-a> --database <schema-name> query "SELECT * FROM projects_task WHERE id = 47515"
./database --db <connection-b> --database <schema-name> query "SELECT * FROM projects_task WHERE id = 47515"

# Test a query in one environment before running in another
./database --db <connection-a> --database <schema-name> query "SELECT * FROM new_feature_table LIMIT 5"
./database --db <connection-b> --database <schema-name> query "SELECT * FROM new_feature_table LIMIT 5"
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
- Test with: `./database test`

### Command location
Do not assume a `database` command exists on `PATH`. Locate the skill directory and run `./database ...`, or use the absolute path to the skill's `database` executable.

### `No database selected`
You selected a connection but not a schema. Add `--database <schema-name>`:

```bash
./database --db <connection-name> --database <schema-name> tables
./database --db <connection-name> --database <schema-name> query "SELECT * FROM projects_task LIMIT 5"
```

If you do not know the schema name:

```bash
./database --db <connection-name> show-databases
```

### "mysql client not found"
Install MySQL client:
- macOS: `brew install mysql-client`
- Linux: `apt-get install mysql-client`

### Query errors
- Use `./database tables` to see available tables
- Use `./database describe <table>` to see columns
- Check SQL syntax
- Ensure query is SELECT-only
- If JSON output fails, rerun without `json` or use `csv`; not all MySQL clients support `--json`

## Support

For issues or feature requests, please contact the Sytex team.
