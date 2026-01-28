---
name: sytex-reports
description: Generate reports from Sytex data (tasks, projects, forms, users, organizations). Use when user asks for reports, statistics, or data analysis from any Sytex instance.
allowed-tools:
  - Bash(~/.claude/skills/database/*:*)
  - Read
---

# Sytex Reports

Generate reports and analytics from Sytex databases using direct SQL queries.

## Prerequisites

This skill requires the **database** skill to be configured with Sytex database connections.

## Architecture Overview

Sytex uses a multi-tenant architecture:

```
Connection (us/eu)
  └── Database (sytex_<instance>)
        └── Organization (org_id)
              └── Data (tasks, projects, forms, etc.)
```

### Connections

| Connection | Region | Description |
|------------|--------|-------------|
| `us` | Americas | US-East AWS region, most instances |
| `eu` | Europe | EU region (app_eu instance) |

### Instances (Databases)

Each instance is a separate database named `sytex_<instance_name>`:

| Instance | Database | Description |
|----------|----------|-------------|
| app | sytex_app | Main production instance |
| app_eu | sytex_app (eu connection) | European instance |
| claro | sytex_claro | Claro telecom |
| ufinet | sytex_ufinet | Ufinet |
| dt | sytex_dt | Deutsche Telekom |
| adc | sytex_adc | ADC |
| atis | sytex_atis | ATIS |
| exsei | sytex_exsei | Exsei |
| integrar | sytex_integrar | Integrar |
| torresec | sytex_torresec | Torresec |
| telesoluciones | sytex_telesoluciones | Telesoluciones |

**To list all available databases:**
```bash
~/.claude/skills/database/database --db us show-databases
```

### Organizations

Each database contains multiple organizations. Every major table has an `organization_id` column to filter data by organization.

**To find an organization by name:**
```bash
~/.claude/skills/database/database --db us --database sytex_app query "
SELECT id, name, country
FROM organizations_organization
WHERE name LIKE '%search_term%' AND is_inactive = 0
" table
```

## Report Workflow

When a user requests a report, follow this workflow:

### 1. Identify the Target

Ask or determine:
- **Organization name** - which organization the report is for
- **Instance** - if not clear, search across instances or use sytex_app as default
- **Connection** - use `us` unless the organization is European (app_eu)

### 2. Find the Organization ID

```bash
# Search in the main instance
~/.claude/skills/database/database --db us --database sytex_app query "
SELECT id, name, country
FROM organizations_organization
WHERE name LIKE '%Telecom%' AND is_inactive = 0
" table
```

If not found, try other instances or use the sytex skill's `find-org` command.

### 3. Verify Table Schema

**ALWAYS check the schema before writing queries:**

```bash
~/.claude/skills/database/database --db us --database sytex_app describe projects_task
```

### 4. Build and Execute Query

Always filter by `organization_id` and use appropriate date ranges.

## Core Tables Reference

### Organizations

```sql
-- Table: organizations_organization
-- Key fields: id, name, country, is_inactive
```

### Users & People

```sql
-- Table: sytexauth_user
-- Key fields: id, email, profile_id, is_inactive, last_activity

-- Table: people_profile
-- Key fields: id, name, email, organization_id

-- Join users with profiles:
SELECT u.id, u.email, p.name
FROM sytexauth_user u
JOIN people_profile p ON u.profile_id = p.id
WHERE p.organization_id = <org_id>
```

### Tasks

```sql
-- Table: projects_task
-- Key fields: id, code, name, status_id, organization_id, project_id,
--             plan_date, start_date, finish_date, when_created, when_closed,
--             assigned_staff_id, is_inactive

-- Status meanings (check shared_status table):
-- is_closed = 1: task is closed
-- is_finished = 1: task is completed
-- is_cancelled = 1: task was cancelled
```

### Projects

```sql
-- Table: projects_project
-- Key fields: id, code, name, status_id, organization_id, client_id,
--             start_date, finish_date
```

### Forms

```sql
-- Table: forms_form
-- Key fields: id, code, status_id, organization_id, form_template_id

-- Table: forms_formcontent (contains form answers as JSON)
-- Key fields: id, form_id, content, organization_id
```

### Work Structures (Workflows/WBS)

```sql
-- Table: projects_workstructure
-- Key fields: id, code, name, status_id, organization_id, project_id
```

### Materials

```sql
-- Table: warehouse_materialoperation
-- Key fields: id, code, status_id, organization_id
```

### Status Reference

```sql
-- Table: shared_status
-- Key fields: id, name, is_closed, is_finished, is_cancelled, content_type_id
-- Note: status applies to different entities (tasks, projects, forms, etc.)
```

## Common Report Queries

### Tasks Completed This Month

```bash
~/.claude/skills/database/database --db us --database sytex_app query "
SELECT
    COUNT(*) as total_completed,
    DATE(finish_date) as date
FROM projects_task t
JOIN shared_status s ON t.status_id = s.id
WHERE t.organization_id = <org_id>
  AND t.is_inactive = 0
  AND s.is_finished = 1
  AND t.finish_date >= DATE_FORMAT(NOW(), '%Y-%m-01')
  AND t.finish_date < DATE_FORMAT(NOW() + INTERVAL 1 MONTH, '%Y-%m-01')
GROUP BY DATE(finish_date)
ORDER BY date
" table
```

### Tasks by Status

```bash
~/.claude/skills/database/database --db us --database sytex_app query "
SELECT
    s.name as status,
    COUNT(*) as count
FROM projects_task t
JOIN shared_status s ON t.status_id = s.id
WHERE t.organization_id = <org_id>
  AND t.is_inactive = 0
GROUP BY s.id, s.name
ORDER BY count DESC
" table
```

### Active Users (Last 30 Days)

```bash
~/.claude/skills/database/database --db us --database sytex_app query "
SELECT
    p.name,
    u.email,
    u.last_activity
FROM sytexauth_user u
JOIN people_profile p ON u.profile_id = p.id
WHERE p.organization_id = <org_id>
  AND u.is_inactive = 0
  AND u.last_activity >= NOW() - INTERVAL 30 DAY
ORDER BY u.last_activity DESC
LIMIT 50
" table
```

### Forms Created by Template

```bash
~/.claude/skills/database/database --db us --database sytex_app query "
SELECT
    ft.name as template_name,
    COUNT(*) as form_count
FROM forms_form f
JOIN forms_formtemplate ft ON f.form_template_id = ft.id
WHERE f.organization_id = <org_id>
  AND f.is_inactive = 0
GROUP BY ft.id, ft.name
ORDER BY form_count DESC
" table
```

### Projects Summary

```bash
~/.claude/skills/database/database --db us --database sytex_app query "
SELECT
    p.code,
    p.name,
    s.name as status,
    p.start_date,
    p.finish_date,
    (SELECT COUNT(*) FROM projects_task t WHERE t.project_id = p.id AND t.is_inactive = 0) as task_count
FROM projects_project p
JOIN shared_status s ON p.status_id = s.id
WHERE p.organization_id = <org_id>
  AND p.is_inactive = 0
ORDER BY p.start_date DESC
LIMIT 20
" table
```

## Output Formats

The database skill supports three output formats:

- `table` - Human-readable table (default, best for reports)
- `json` - JSON array (useful for further processing)
- `csv` - CSV format (good for exports)

```bash
# JSON output example
~/.claude/skills/database/database --db us --database sytex_app query "SELECT ..." json

# CSV output example
~/.claude/skills/database/database --db us --database sytex_app query "SELECT ..." csv
```

## Best Practices

1. **Always filter by organization_id** - Multi-tenant data requires org filtering
2. **Check is_inactive = 0** - Exclude soft-deleted records
3. **Use LIMIT** - Avoid overwhelming output, especially on first queries
4. **Verify schema first** - Use `describe` before writing complex queries
5. **Use appropriate date functions** - `DATE_FORMAT`, `DATE()`, `NOW()`, `INTERVAL`
6. **Join with status table** - For human-readable status names

## Troubleshooting

### Organization Not Found
Try searching in other instances:
```bash
~/.claude/skills/database/database --db us --database sytex_claro query "SELECT id, name FROM organizations_organization WHERE name LIKE '%search%'"
```

Or use the sytex skill to search across all instances:
```bash
~/.claude/skills/sytex/sytex find-org "organization name"
```

### Connection Errors
Test the database connection:
```bash
~/.claude/skills/database/database --db us test
```

### Unknown Column
Always verify table schema before querying:
```bash
~/.claude/skills/database/database --db us --database sytex_app describe table_name
```
