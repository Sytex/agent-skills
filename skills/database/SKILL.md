---
name: database
description: Read-only access to configured databases for schema inspection and SQL querying across environments.
---

# Database Skill

You now have **read-only** access to multiple databases through the bundled `database` executable. This skill supports connecting to any configured database connection.

Always assume the executable is **not** installed on `PATH`. Before running database commands, locate this skill's directory and run the bundled executable from there:

```bash
./database help
```

If your current working directory is not the skill directory, use the absolute path to the skill's `database` executable. This applies across Codex, Claude Code, and other shell-based agent environments.

All command examples below use `./database` and assume the shell is already in the database skill directory.

## Important Safety Rules

1. **READ-ONLY ACCESS**: This skill only allows SELECT, SHOW, DESCRIBE, and EXPLAIN queries
2. **NO MODIFICATIONS**: You cannot INSERT, UPDATE, DELETE, or modify any data
3. **QUERY VALIDATION**: All queries are validated before execution
4. **PRODUCTION DATA**: Treat all data as sensitive and confidential
5. **MULTIPLE DATABASES**: You can configure and switch between multiple database connections

## Available Commands

### Managing Multiple Databases

```bash
./database dbs
```
List all configured database connections with their connection status. Shows which database is currently active.

**Using a specific connection and schema:**
```bash
./database --db <connection-name> <command>
./database --db <connection-name> --database <schema-name> query "SELECT * FROM tasks"
./database --db <connection-name> --database <schema-name> tables
```

If you don't specify `--db`, the default connection will be used (usually the first one configured).

Important terminology:
- `--db <connection-name>` selects the configured connection/environment.
- `--database <schema-name>` selects the actual MySQL/MariaDB database/schema on that connection.

If a command returns `No database selected`, keep the same `--db` value and add `--database <schema-name>`. Use `show-databases` to discover available schemas:

```bash
./database --db <connection-name> show-databases
```

### Connection Testing
```bash
./database test
```
Test database connectivity and show connection details for the active database.

```bash
./database --db <connection-name> test
```
Test connection to a specific database.

### Database Exploration
```bash
./database tables
```
List all tables in the database.

If the selected connection does not have a default schema configured, include `--database <schema-name>`:

```bash
./database --db <connection-name> --database <schema-name> tables
```

```bash
./database describe <table_name>
```
Show the schema (columns, types) and indexes for a specific table.

```bash
./database stats
```
Show database statistics including row counts for all tables.

### Custom Queries
```bash
./database query "SELECT * FROM tasks WHERE status = 'open' LIMIT 10"
```
Execute a custom SELECT query. Returns results in table format.

```bash
./database query "SELECT COUNT(*) FROM users" json
```
Execute a query and return results in JSON format (useful for parsing).

Supported formats:
- `table` (default) - Human-readable table format
- `json` - JSON array of objects
- `csv` - Comma-separated values

Format is a positional argument after the SQL string, not a global flag. Do this:

```bash
./database --database <schema-name> query "SELECT COUNT(*) FROM users" json
```

Do not do this:

```bash
./database --database <schema-name> query "SELECT COUNT(*) FROM users" --json
```

Some installed MySQL clients do not support JSON output. If `json` returns an error such as `unknown option '--json'`, rerun the query using the default table output or `csv`.

## Usage Guidelines

### When to Use This Skill

Use this skill when you need to:
- Investigate data issues or bugs
- Answer questions about production data
- Generate reports or statistics
- Understand data relationships
- Debug API behavior by checking database state
- Validate data integrity

### Best Practices

1. **Start with exploration**: Use `tables` and `describe` to understand the schema
2. **Use LIMIT**: Always limit results to avoid overwhelming output
3. **Use the right selector flags**: Use `--db` for the configured connection and `--database` for the schema
4. **Test connectivity**: If queries fail, run `./database test` to check connection
5. **Be specific**: Include relevant WHERE clauses to filter data
6. **Protect sensitive data**: Don't expose passwords, tokens, or PII unnecessarily

### CRITICAL: Always Check Schema Before Writing Queries

**⚠️ MANDATORY PROCEDURE: Before writing ANY custom query, you MUST verify the table schema first.**

This prevents column name errors and ensures your queries work correctly.

#### Workflow:

1. **Identify the tables** you need to query
2. **Check the schema** of each table using `describe`
3. **Write your query** using the actual column names from the schema
4. **Execute the query**

#### Example Workflow:

**❌ WRONG - Don't do this:**
```bash
# Directly querying without checking schema
./database query "SELECT id, name, status FROM projects_task LIMIT 5"
# Error: Unknown column 'status' - should be 'status_id'
```

**✅ CORRECT - Always do this:**

```bash
# Step 1: Check the schema first
./database describe projects_task

# Step 2: Review the output to see actual columns
# Output shows: id, code, name, status_id, plan_date, etc.

# Step 3: Write query with correct column names
./database query "SELECT id, code, name, status_id, plan_date FROM projects_task LIMIT 5"
```

If your connection needs an explicit schema, include it consistently:

```bash
./database --db <connection-name> --database <schema-name> describe projects_task
./database --db <connection-name> --database <schema-name> query "SELECT id, code FROM projects_task LIMIT 5"
```

#### Real Example with JOINs:

```bash
# Step 1: Check both table schemas
./database describe sytexauth_user
./database describe people_profile

# Step 2: Identify join columns and field names
# sytexauth_user has: id, email, profile_id
# people_profile has: id, name

# Step 3: Write the JOIN query correctly
./database query "
SELECT u.id, u.email, p.name
FROM sytexauth_user u
JOIN people_profile p ON u.profile_id = p.id
WHERE u.id = 1
"
```

#### Quick Schema Reference Commands:

```bash
# List all tables
./database tables

# Describe a specific table (shows columns, types, keys)
./database describe projects_task

# Describe multiple tables before complex queries
./database describe sytexauth_user
./database describe people_profile
./database describe projects_project
```

### Working with Multiple Databases

When you have multiple database connections configured, you can easily switch between them:

```bash
# List all configured connections
./database dbs

# Compare data between environments
./database --db <connection-a> --database <schema-name> query "SELECT COUNT(*) FROM projects_task"
./database --db <connection-b> --database <schema-name> query "SELECT COUNT(*) FROM projects_task"

# Check schema differences
./database --db <connection-a> --database <schema-name> describe projects_task
./database --db <connection-b> --database <schema-name> describe projects_task

# Debug issues by checking the same record in two connections
./database --db <connection-a> --database <schema-name> query "SELECT * FROM projects_task WHERE id = 47515"
./database --db <connection-b> --database <schema-name> query "SELECT * FROM projects_task WHERE id = 47515"

# Test queries in one environment before running in another
./database --db <connection-a> --database <schema-name> query "SELECT COUNT(*) FROM users WHERE last_activity > NOW() - INTERVAL 30 DAY"
./database --db <connection-b> --database <schema-name> query "SELECT COUNT(*) FROM users WHERE last_activity > NOW() - INTERVAL 30 DAY"
```

**Default Database:**
If you don't specify `--db`, the first configured connection is used by default. A connection may still require `--database <schema-name>` if no default schema is configured.

### Query Examples

**Find tasks by status:**
```bash
./database query "SELECT id, title, status FROM tasks WHERE status = 'in_progress' LIMIT 10"
```

**Count records by type:**
```bash
./database query "SELECT status, COUNT(*) as count FROM tasks GROUP BY status"
```

**Join queries:**
```bash
./database query "
SELECT t.title, p.name as project_name
FROM tasks t
JOIN projects p ON t.project_id = p.id
LIMIT 10
"
```

**Check specific record:**
```bash
./database query "SELECT * FROM tasks WHERE id = 12345"
```

## Troubleshooting

### Connection Errors
If you get connection errors:
1. Run `./database test` to verify credentials
2. Check that database host is accessible
3. Verify database user has SELECT permissions

### Command Location
Do not assume a `database` command exists on `PATH`. Locate the skill directory and run `./database ...`, or use the absolute path to the skill's `database` executable. This is common when using the same skill across different agents such as Codex and Claude Code.

### No Database Selected
If you get `No database selected`, you selected a connection but not a schema. Add `--database <schema-name>`:

```bash
./database --db <connection-name> --database <schema-name> tables
./database --db <connection-name> --database <schema-name> query "SELECT * FROM projects_task LIMIT 5"
```

If you do not know the schema name:

```bash
./database --db <connection-name> show-databases
```

### Query Errors
- **Syntax errors**: Double-check SQL syntax
- **Table doesn't exist**: Use `./database tables` to see available tables
- **Column doesn't exist**: Use `./database describe <table>` to see columns
- **Blocked query**: Only SELECT queries allowed - modify your query to read-only
- **JSON output fails**: Some MySQL clients do not support `--json`; rerun without `json` or use `csv`

### Missing mysql Client
If you get "mysql client not found":
- macOS: `brew install mysql-client`
- Linux: `apt-get install mysql-client` or `yum install mysql`

## Security Notes

- This skill uses a read-only database user
- All queries are validated to prevent modifications
- Credentials are stored in `.env` file (never commit this)
- Production data should be treated as confidential
- Don't share query results containing sensitive information

## Getting Help

For command usage:
```bash
./database help
```

For table-specific information:
```bash
./database describe <table_name>
```
