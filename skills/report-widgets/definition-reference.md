# Definition Reference

The `definition` JSON is the core of a widget. It describes what data to query and how to display it.

## Sources

Data warehouse tables to query. First source is the FROM table.

```json
"sources": [
  {"id": "t", "entity_type": "tasks"},
  {"id": "f", "entity_type": "forms"}
]
```

`id` is an alias used throughout the definition to reference this source.

### Available entity types

| entity_type | Description | Key columns |
|-------------|-------------|-------------|
| `tasks` | Tasks | task_code, task_name, task_status, project_code, project_name, task_assigned_staff_name, task_assigned_supplier_name, task_request_date, task_finish_plan_date, task_last_completed_date, task_url, workflow_template_name |
| `forms` | Forms | form_code, form_name, form_status, template_name, template_code, project_code, project_name, form_assigned_user_name, form_last_submitted_date, form_url |
| `entry_answers` | Form field answers | form_code, form_template_code, answer_entry_label, answer_value, answer_index, task_code, project_code |
| `sites` | Sites | site_code, site_name, site_type, client_name, country, latitude, longitude |
| `workstructures` | Workflows | workstructure_code, workstructure_status, project_name |
| `custom_fields` | Custom fields | custom_field_name, custom_field_value, entity_type |
| `materials` | Materials | material_code, material_name, material_category |
| `simple_operations` | Material operations | operation_code, operation_status |
| `purchase_orders` | Purchase orders | po_code, po_status, supplier_name |
| `quotations` | Quotations | quotation_code, quotation_status |
| `stoppers` | Stoppers | stopper_type, stopper_status |

> Always fetch the schema first (`definition_schema`) to get the exact columns available for each entity type. The list above is a summary.

## Columns

SELECT columns. Each references a source alias and column id.

```json
"columns": [
  {"source": "t", "id": "task_status"},
  {"source": "t", "id": "project_name", "alias": "project"}
]
```

## Computed Columns

Derived fields using SQL expressions. Can be referenced in aggregations.

```json
"computed_columns": [
  {
    "expression": "DATEDIFF(`t`.`task_last_completed_date`, `t`.`task_availability_date`)",
    "alias": "days_to_close"
  },
  {
    "expression": "DATE_FORMAT(`t`.`task_last_completed_date`, '%Y-%m')",
    "alias": "month"
  }
]
```

## Aggregations

Aggregate functions. Require `group_by` when used with columns.

```json
"aggregations": [
  {"function": "COUNT", "column": "*", "alias": "total"},
  {"function": "SUM", "column": "amount", "alias": "total_amount"},
  {"function": "AVG", "column": "days_to_close", "alias": "avg_days"},
  {"function": "MIN", "column": "created_at", "alias": "earliest"},
  {"function": "MAX", "column": "created_at", "alias": "latest"},
  {"function": "COUNT", "expression": "DISTINCT `t`.`project_name`", "alias": "unique_projects"}
]
```

- `column` references a column id or computed_column alias
- `expression` allows raw SQL (use for DISTINCT or complex expressions)
- Functions: COUNT, SUM, AVG, MIN, MAX

## Joins

Combine multiple sources. Uses column mapping between sources.

```json
"joins": [
  {"from": "ea", "to": "f", "type": "inner", "on": {"form_code": "form_code"}}
]
```

- `type`: `inner`, `left`, `right`
- `on`: maps `{from_column: to_column}` — generates `from.from_column = to.to_column`
- Common join patterns:
  - entry_answers → forms: `{"form_code": "form_code"}`
  - forms → tasks: `{"task_code": "task_code"}`
  - tasks → sites: `{"site_id": "entity_id"}`

## Base Filters

Always-applied filters. Not visible to the user.

```json
"base_filters": [
  {"source": "t", "id": "task_status", "type": "fixed_options", "value": {"options": [{"id": "Completed"}]}},
  {"source": "f", "id": "project_code", "type": "text_starts_with", "value": "SOL"}
]
```

## Interactive Filters

User-facing filters. Users can change values at runtime through the UI.

```json
"interactive_filters": [
  {
    "source": "t",
    "id": "task_last_completed_date",
    "type": "date",
    "label": "Period",
    "default": {"relative": "last_three_months"}
  },
  {
    "source": "t",
    "id": "task_status",
    "type": "fixed_options",
    "label": "Status",
    "default": null,
    "options": [
      {"id": "Pending", "name": "Pending"},
      {"id": "Completed", "name": "Completed"}
    ]
  }
]
```

## Filter Types

| Type | Value format | Description |
|------|-------------|-------------|
| `date` | `{"relative": "this_month"}` | Relative date |
| `date` | `{"exact": "2024-01-15"}` | Exact date |
| `date` | `{"gte": "2024-01-01", "lte": "2024-12-31"}` | Date range |
| `date` | `{"value_is_empty": true}` | NULL check |
| `options` | `[{"id": "val1"}, {"id": "val2"}]` | Dynamic options (IN clause) |
| `fixed_options` | `{"options": [{"id": "val1"}]}` | Static predefined options (IN clause) |
| `text` | `"exact value"` | Exact text match (=) |
| `text_starts_with` | `"SOL"` | Starts with (LIKE 'SOL%') |
| `text_contains` | `"cable"` | Contains (LIKE '%cable%') |
| `boolean` | `true` / `false` | Boolean |

### Relative dates

`yesterday`, `today`, `tomorrow`, `this_week`, `this_month`, `this_year`, `last_week`, `last_month`, `last_three_months`, `last_six_months`, `last_year`, `last_hour`

## Group By

Required when using aggregations with columns. Uses `` `source`.`column` `` format.

```json
"group_by": ["`t`.`task_status`", "`t`.`project_name`"]
```

## Order By

Sort results. Can use column aliases.

```json
"order_by": ["total DESC", "project_name ASC"]
```

## Drill Down

Detail rows shown when user clicks a chart element. Omit if not needed.

```json
"drill_down": {
  "columns": [
    {"source": "t", "id": "task_code", "alias": "code"},
    {"source": "t", "id": "task_name", "alias": "name"},
    {"source": "t", "id": "task_url", "alias": "url"}
  ]
}
```

## Visualization

How to render the data.

| Type | Config | Description |
|------|--------|-------------|
| `bar` | `x_axis`, `y_axis[]` | Vertical bar chart |
| `stacked_bar` | `x_axis`, `y_axis[]`, `group_by` | Stacked bar (needs group_by to split bars) |
| `line` | `x_axis`, `y_axis[]` | Line chart (trends over time) |
| `pie` | `x_axis`, `y_axis[]` (one item) | Pie chart (proportions) |
| `number` | `value`, `label` (optional) | Single KPI number |
| `table` | (none) | Data table, shows all columns |

```json
"visualization": {
  "type": "bar",
  "config": {"x_axis": "task_status", "y_axis": ["total"]}
}
```

## Transform Script (advanced)

Optional Python script for post-processing. Receives `rows` (list of lists) and `columns` (list of strings). Must return `{"rows": [...], "columns": [...]}`.

```json
"transform_script": "result = {'columns': columns, 'rows': sorted(rows, key=lambda r: r[0])}"
```
