---
name: sytex-reports
description: |
  This skill should be used when the user asks about Sytex data: tasks, projects,
  forms, sites, clients, materials, workflows, users, or AI credits consumption.
  Trigger phrases: "how many tasks", "tasks completed by", "AI credits consumed",
  "report from Sytex", "statistics for [org name]", "data from [instance]".
  Covers organizations in: app, claro, ufinet, dt, adc, atis, exsei, integrar,
  torresec, telesoluciones.
allowed-tools:
  - Bash(~/.claude/skills/database/*:*)
  - Read
---

# Sytex Reports

Generate reports from Sytex using the Data Warehouse (primary) or instance databases.

## Decision Flow

```
What type of report?
├── Business (tasks, forms, projects, sites, clients...) → Data Warehouse
├── Metrics/AI consumption → sytex_*/metrics_* tables
└── Other/Unknown → Discovery in sytex_*
```

## 1. Data Warehouse (Primary Source)

Pre-aggregated, denormalized tables. **No JOINs needed.**

### Architecture
```
Database: data_warehouse
Tables: {org_id}_dw_{entity}
Example: 113_dw_task = Tasks for org 113 (IHS Towers)
```

### Find org_id by Name

Search across all instances:
```bash
for db in sytex_app sytex_claro sytex_ufinet sytex_dt sytex_adc sytex_atis sytex_exsei sytex_integrar sytex_torresec sytex_telesoluciones; do
  ~/.claude/skills/database/database --db us --database $db query "
    SELECT '$db' as instance, id as org_id, name
    FROM organizations_organization
    WHERE name LIKE '%SEARCH_TERM%' AND is_inactive = 0
  " table 2>/dev/null | grep -v "mysql:" | grep -v "^$"
done
```

### Available Entities

| Entity | Description |
|--------|-------------|
| `task` | Tasks (includes project, workflow, client, sites, staff) |
| `form` | Forms |
| `workstructure` | Workflows/WBS |
| `site` | Sites |
| `networkelement` | Network elements |
| `client` | Clients |
| `material` / `materialstock` | Materials and stock |
| `profile` | User profiles |
| `purchaseorder` / `purchaseorderitem` | Purchase orders |
| `quotation` / `quotationitem` | Quotations |
| `simpleoperation` / `simpleoperationitem` | Simple operations |
| `entryanswer` | Form answers |
| `customfield` | Custom fields |
| `taskstatushistory` / `formstatushistory` | Status history |
| `chatmetrics` | Chat metrics |
| `stopper` | Stoppers |
| `taskdocument` | Task documents |
| `siteaccessrequest` | Site access requests |

### Example Query

```bash
# Tasks completed this month for org 113
~/.claude/skills/database/database --db us --database data_warehouse query "
SELECT task_code, task_name, task_status, project_name,
       task_finish_date, task_assigned_staff_name
FROM 113_dw_task
WHERE task_finish_date >= DATE_FORMAT(NOW(), '%Y-%m-01')
  AND task_status = 'Completada'
ORDER BY task_finish_date DESC
LIMIT 20
" table
```

The `_dw_task` table has ~90 columns including: task_code, task_name, task_status, project_code, project_name, client_name, site_codes, assigned_staff_email, all dates, task_url, etc.

## 2. Metrics (AI Credits, API Costs)

Metrics are in instance databases, NOT in data warehouse.

### AI Credits Consumption
```bash
~/.claude/skills/database/database --db us --database sytex_<instance> query "
SELECT
    DATE_FORMAT(date_time, '%Y-%m') as month,
    SUM(amount) as credits,
    COUNT(*) as transactions
FROM metrics_meteredproductusage
WHERE unit_name = 'sytex_ai_credit'
  AND date_time >= '2025-01-01' AND date_time < '2026-01-01'
GROUP BY DATE_FORMAT(date_time, '%Y-%m')
ORDER BY month
" table
```

### Third Party API Costs
```bash
~/.claude/skills/database/database --db us --database sytex_<instance> query "
SELECT provider_name, ROUND(SUM(total_price), 2) as cost_usd, SUM(amount) as units
FROM metrics_thirdpartyserviceusage
WHERE date_time >= '2025-01-01' AND date_time < '2026-01-01'
GROUP BY provider_name
ORDER BY cost_usd DESC
" table
```

## 3. Discovery (For Everything Else)

When unsure which table to use:

```bash
# List tables matching keyword
~/.claude/skills/database/database --db us --database sytex_<instance> tables 2>&1 | grep -i "keyword"

# Check schema
~/.claude/skills/database/database --db us --database sytex_<instance> describe table_name

# Sample data
~/.claude/skills/database/database --db us --database sytex_<instance> query "SELECT * FROM table_name LIMIT 5" table

# List distinct values
~/.claude/skills/database/database --db us --database sytex_<instance> query "SELECT DISTINCT column FROM table_name" table
```

## Connections

| Connection | Instances |
|------------|-----------|
| `us` | app, claro, ufinet, dt, adc, atis, exsei, integrar, torresec, telesoluciones |
| `eu` | app_eu |

## Best Practices

1. **Use Data Warehouse first** - It's denormalized and fast
2. **Filter by is_inactive = 0** - Exclude deleted records (in sytex_* tables)
3. **Use LIMIT** - Especially on first queries
4. **Verify schema** - Use `describe` when unsure about columns
