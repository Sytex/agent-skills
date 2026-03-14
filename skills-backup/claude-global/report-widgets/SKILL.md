---
name: report-widgets
description: |
  This skill should be used when the user asks to "create a report widget", "make a chart",
  "build a dashboard widget", "KPI for tasks", "visualize form data", "bar chart of projects",
  "report widget", "stacked bar", "line chart", "pie chart", or wants to aggregate and
  visualize data from Sytex entities (tasks, forms, entry answers, sites, workflows, etc.).
  Also use when the user mentions report widget definitions, previews, or drill-downs.
---

# Report Widget Builder

Create report widgets in Sytex via the API. Widgets are SQL-based data visualizations (charts, tables, KPIs) configured through a JSON definition.

## Workflow

1. **Understand the request** — What data? What visualization? What filters?
2. **Fetch the schema** — Get available entities, columns, and filter types via `schema`
3. **Discover data** — Use `column-values` to find actual values (statuses, template codes, project codes). Values are translated and org-specific, so discovering them prevents building widgets with wrong filter values.
4. **Confirm with the user** — Verify the date filter default range before building
5. **Build the definition** — Construct the JSON definition (see `definition-reference.md`)
6. **Preview** — Test the definition and verify the returned data makes sense
7. **Validate** — Re-read the original request and check: are all conditions covered? Missing a filter is the most common mistake.
8. **Create** — Save the widget

## API

This skill includes an `api` script. Configuration (token, URL, org ID) is stored in `.env` alongside the script.

Run `api` without arguments to see usage help.

### Commands

| Command | Description |
|---------|-------------|
| `api list` | List all widgets |
| `api get <id>` | Get widget details |
| `api create '<json>'` | Create a widget |
| `api update <id> '<json>'` | Update a widget (partial) |
| `api delete <id>` | Delete a widget |
| `api preview '<json>'` | Preview a definition before saving |
| `api data <id> ['<json>']` | Get widget data with optional filters |
| `api schema` | Get definition schema (entities, columns, filter types) |
| `api column-values <entity> <col>` | Get distinct values for a column |
| `api ous` | List operational units |

### Create request body

```json
{
  "name": "Widget name",
  "description": "Optional description",
  "is_active": true,
  "for_creator_only": false,
  "operational_units": ["<ou-id>"],
  "definition": { ... }
}
```

### Preview request body

```json
{
  "definition": { ... },
  "filters": {},
  "drill_down": null
}
```

Preview returns `{"columns": [...], "rows": [...]}` — use this to catch SQL errors before creating.

## Data Discovery

Before building a widget, discover actual data values. Statuses, field labels, and project names are **translated per organization** — "Completed" in one org is "Completada" in another, "Submitted" is "Enviado". Hardcoding assumed values produces widgets that return no data or wrong data.

```bash
api column-values <entity_type> <column>
```

Returns `{"entity_type": "...", "column": "...", "values": [...]}` — up to 200 distinct values, sorted.

Examples:
```bash
# Statuses
api column-values tasks task_status
api column-values forms form_status
api column-values workstructures workstructure_status

# Codes and identifiers
api column-values tasks project_code
api column-values sites site_type
api column-values entry_answers form_template_code
```

## Key Principles

- **Identifiers over names** — Filter by code, id, or index when available. Names are translated and can change; identifiers are stable across languages. Use `template_code` over `template_name`, `project_code` over `project_name`, etc. Only use names (like status names) when there's no identifier alternative.

- **`answer_index` requires a template filter** — The same index (e.g., "1.8") exists across many form templates with completely different meanings (cable length in one, certificates in another). Querying `entry_answers` without filtering by `form_template_code` mixes unrelated data and produces incorrect aggregations.

- **Include a date filter** — Most widgets benefit from an interactive date filter on a meaningful date column (submission date, completion date, etc.). Confirm the default range with the user. Only skip for truly timeless data.

- **Preview before creating** — Catches SQL errors and lets you verify the data matches the requirement.

- **`answer_value` is TEXT** — Cast to DECIMAL for numeric aggregations: `CAST(\`ea\`.\`answer_value\` AS DECIMAL(10,2))`

- **Join entry_answers to forms on `form_code`** — Use `{"form_code": "form_code"}`, not `{"form_id": "entity_id"}`

- **`group_by` format** — Always backtick-quoted: `` `source`.`column` ``

- **Row limit** — Max 10,000 rows per query

- **Operational units** — Required when creating. Run `api ous` to get available OUs.

## Reference Files

For detailed definition syntax, filter types, visualization options, and examples:

- **`definition-reference.md`** — Full definition JSON reference: sources, columns, computed columns, aggregations, joins, filters, group_by, order_by, drill_down, visualization types, transform scripts
- **`examples.md`** — Complete widget examples: bar chart, KPI number, stacked bar, line chart, entry_answers join, conditional aggregation (multiple metrics)
- **`data-model.md`** — Conceptual guide to Sytex data structure: projects, tasks, forms, entry answers, locations, and their relationships
