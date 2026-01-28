# Database Skill

You now have **read-only** access to multiple databases through the `database` command. This skill supports connecting to production, staging, local, or any other configured database.

## Important Safety Rules

1. **READ-ONLY ACCESS**: This skill only allows SELECT, SHOW, DESCRIBE, and EXPLAIN queries
2. **NO MODIFICATIONS**: You cannot INSERT, UPDATE, DELETE, or modify any data
3. **QUERY VALIDATION**: All queries are validated before execution
4. **PRODUCTION DATA**: Treat all data as sensitive and confidential
5. **MULTIPLE DATABASES**: You can configure and switch between multiple database connections

## Available Commands

### Managing Multiple Databases

```bash
database dbs
```
List all configured database connections with their connection status. Shows which database is currently active.

**Using a specific database:**
```bash
database --db production <command>
database --db staging query "SELECT * FROM tasks"
database --db local tables
```

If you don't specify `--db`, the default database will be used (usually the first one configured).

### Connection Testing
```bash
database test
```
Test database connectivity and show connection details for the active database.

```bash
database --db staging test
```
Test connection to a specific database.

### Database Exploration
```bash
database tables
```
List all tables in the database.

```bash
database describe <table_name>
```
Show the schema (columns, types) and indexes for a specific table.

```bash
database stats
```
Show database statistics including row counts for all tables.

### Custom Queries
```bash
database query "SELECT * FROM tasks WHERE status = 'open' LIMIT 10"
```
Execute a custom SELECT query. Returns results in table format.

```bash
database query "SELECT COUNT(*) FROM users" json
```
Execute a query and return results in JSON format (useful for parsing).

Supported formats:
- `table` (default) - Human-readable table format
- `json` - JSON array of objects
- `csv` - Comma-separated values

## Usage Guidelines

### When to Use This Skill

Use `database` when you need to:
- Investigate data issues or bugs
- Answer questions about production data
- Generate reports or statistics
- Understand data relationships
- Debug API behavior by checking database state
- Validate data integrity

### Best Practices

1. **Start with exploration**: Use `tables` and `describe` to understand the schema
2. **Use LIMIT**: Always limit results to avoid overwhelming output
3. **Use predefined queries**: When available, use shortcuts like `database tasks` instead of raw SQL
4. **Test connectivity**: If queries fail, run `database test` to check connection
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
database query "SELECT id, name, status FROM projects_task LIMIT 5"
# Error: Unknown column 'status' - should be 'status_id'
```

**✅ CORRECT - Always do this:**

```bash
# Step 1: Check the schema first
database describe projects_task

# Step 2: Review the output to see actual columns
# Output shows: id, code, name, status_id, plan_date, etc.

# Step 3: Write query with correct column names
database query "SELECT id, code, name, status_id, plan_date FROM projects_task LIMIT 5"
```

#### Real Example with JOINs:

```bash
# Step 1: Check both table schemas
database describe sytexauth_user
database describe people_profile

# Step 2: Identify join columns and field names
# sytexauth_user has: id, email, profile_id
# people_profile has: id, name

# Step 3: Write the JOIN query correctly
database query "
SELECT u.id, u.email, p.name
FROM sytexauth_user u
JOIN people_profile p ON u.profile_id = p.id
WHERE u.id = 1
"
```

#### Quick Schema Reference Commands:

```bash
# List all tables
database tables

# Describe a specific table (shows columns, types, keys)
database describe projects_task

# Describe multiple tables before complex queries
database describe sytexauth_user
database describe people_profile
database describe projects_project
```

### Working with Multiple Databases

When you have multiple databases configured (e.g., production, staging, local), you can easily switch between them:

```bash
# List all configured databases
database dbs

# Compare data between environments
database --db production query "SELECT COUNT(*) FROM projects_task"
database --db staging query "SELECT COUNT(*) FROM projects_task"

# Check schema differences
database --db production describe projects_task
database --db staging describe projects_task

# Debug issues by checking production vs staging
database --db production query "SELECT * FROM projects_task WHERE id = 47515"
database --db staging query "SELECT * FROM projects_task WHERE id = 47515"

# Test queries in staging before running in production
database --db staging query "SELECT COUNT(*) FROM users WHERE last_activity > NOW() - INTERVAL 30 DAY"
# If it works, run in production:
database --db production query "SELECT COUNT(*) FROM users WHERE last_activity > NOW() - INTERVAL 30 DAY"
```

**Default Database:**
If you don't specify `--db`, the first configured database is used by default. You can set a default by configuring `SYTEXDB_DEFAULT_DB` in your .env file.

### Query Examples

**Find tasks by status:**
```bash
database query "SELECT id, title, status FROM tasks WHERE status = 'in_progress' LIMIT 10"
```

**Count records by type:**
```bash
database query "SELECT status, COUNT(*) as count FROM tasks GROUP BY status"
```

**Join queries:**
```bash
database query "
SELECT t.title, p.name as project_name
FROM tasks t
JOIN projects p ON t.project_id = p.id
LIMIT 10
"
```

**Check specific record:**
```bash
database query "SELECT * FROM tasks WHERE id = 12345"
```

## Troubleshooting

### Connection Errors
If you get connection errors:
1. Run `database test` to verify credentials
2. Check that database host is accessible
3. Verify database user has SELECT permissions

### Query Errors
- **Syntax errors**: Double-check SQL syntax
- **Table doesn't exist**: Use `database tables` to see available tables
- **Column doesn't exist**: Use `database describe <table>` to see columns
- **Blocked query**: Only SELECT queries allowed - modify your query to read-only

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
database help
```

For table-specific information:
```bash
database describe <table_name>
```
