# Sytex Database Skill

You are now connected to the Sytex production database with **read-only** access through the `sytex-db` command.

## Important Safety Rules

1. **READ-ONLY ACCESS**: This skill only allows SELECT, SHOW, DESCRIBE, and EXPLAIN queries
2. **NO MODIFICATIONS**: You cannot INSERT, UPDATE, DELETE, or modify any data
3. **QUERY VALIDATION**: All queries are validated before execution
4. **PRODUCTION DATA**: Treat all data as sensitive and confidential

## Available Commands

### Connection Testing
```bash
sytex-db test
```
Test database connectivity and show connection details.

### Database Exploration
```bash
sytex-db tables
```
List all tables in the database.

```bash
sytex-db describe <table_name>
```
Show the schema (columns, types) and indexes for a specific table.

```bash
sytex-db stats
```
Show database statistics including row counts for all tables.

### Custom Queries
```bash
sytex-db query "SELECT * FROM tasks WHERE status = 'open' LIMIT 10"
```
Execute a custom SELECT query. Returns results in table format.

```bash
sytex-db query "SELECT COUNT(*) FROM users" json
```
Execute a query and return results in JSON format (useful for parsing).

Supported formats:
- `table` (default) - Human-readable table format
- `json` - JSON array of objects
- `csv` - Comma-separated values

### Predefined Queries

Common queries are available as shortcuts:

```bash
sytex-db tasks [limit]
```
Show recent tasks ordered by update time (default limit: 20).

```bash
sytex-db projects [limit]
```
Show recent projects (default limit: 20).

```bash
sytex-db users [limit]
```
Show users in the system (default limit: 50).

## Usage Guidelines

### When to Use This Skill

Use `sytex-db` when you need to:
- Investigate data issues or bugs
- Answer questions about production data
- Generate reports or statistics
- Understand data relationships
- Debug API behavior by checking database state
- Validate data integrity

### Best Practices

1. **Start with exploration**: Use `tables` and `describe` to understand the schema
2. **Use LIMIT**: Always limit results to avoid overwhelming output
3. **Use predefined queries**: When available, use shortcuts like `sytex-db tasks` instead of raw SQL
4. **Test connectivity**: If queries fail, run `sytex-db test` to check connection
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
sytex-db query "SELECT id, name, status FROM projects_task LIMIT 5"
# Error: Unknown column 'status' - should be 'status_id'
```

**✅ CORRECT - Always do this:**

```bash
# Step 1: Check the schema first
sytex-db describe projects_task

# Step 2: Review the output to see actual columns
# Output shows: id, code, name, status_id, plan_date, etc.

# Step 3: Write query with correct column names
sytex-db query "SELECT id, code, name, status_id, plan_date FROM projects_task LIMIT 5"
```

#### Real Example with JOINs:

```bash
# Step 1: Check both table schemas
sytex-db describe sytexauth_user
sytex-db describe people_profile

# Step 2: Identify join columns and field names
# sytexauth_user has: id, email, profile_id
# people_profile has: id, name

# Step 3: Write the JOIN query correctly
sytex-db query "
SELECT u.id, u.email, p.name
FROM sytexauth_user u
JOIN people_profile p ON u.profile_id = p.id
WHERE u.id = 1
"
```

#### Quick Schema Reference Commands:

```bash
# List all tables
sytex-db tables

# Describe a specific table (shows columns, types, keys)
sytex-db describe projects_task

# Describe multiple tables before complex queries
sytex-db describe sytexauth_user
sytex-db describe people_profile
sytex-db describe projects_project
```

### Query Examples

**Find tasks by status:**
```bash
sytex-db query "SELECT id, title, status FROM tasks WHERE status = 'in_progress' LIMIT 10"
```

**Count records by type:**
```bash
sytex-db query "SELECT status, COUNT(*) as count FROM tasks GROUP BY status"
```

**Join queries:**
```bash
sytex-db query "
SELECT t.title, p.name as project_name
FROM tasks t
JOIN projects p ON t.project_id = p.id
LIMIT 10
"
```

**Check specific record:**
```bash
sytex-db query "SELECT * FROM tasks WHERE id = 12345"
```

## Troubleshooting

### Connection Errors
If you get connection errors:
1. Run `sytex-db test` to verify credentials
2. Check that database host is accessible
3. Verify database user has SELECT permissions

### Query Errors
- **Syntax errors**: Double-check SQL syntax
- **Table doesn't exist**: Use `sytex-db tables` to see available tables
- **Column doesn't exist**: Use `sytex-db describe <table>` to see columns
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
sytex-db help
```

For table-specific information:
```bash
sytex-db describe <table_name>
```
