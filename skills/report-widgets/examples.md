# Widget Examples

> Status values below ("Completed", "Pending", etc.) are placeholders — discover the actual org-specific values with `column_values` before building.

## Bar chart: Tasks completed per person

```json
{
  "sources": [{"id": "t", "entity_type": "tasks"}],
  "columns": [{"source": "t", "id": "task_assigned_staff_name"}],
  "base_filters": [
    {"source": "t", "id": "task_status", "type": "fixed_options", "value": {"options": [{"id": "Completed"}]}}
  ],
  "interactive_filters": [
    {"source": "t", "id": "task_last_completed_date", "type": "date", "label": "Period", "default": {"relative": "last_three_months"}}
  ],
  "group_by": ["`t`.`task_assigned_staff_name`"],
  "aggregations": [{"function": "COUNT", "column": "*", "alias": "total"}],
  "order_by": ["total DESC"],
  "visualization": {"type": "bar", "config": {"x_axis": "task_assigned_staff_name", "y_axis": ["total"]}},
  "drill_down": {
    "columns": [
      {"source": "t", "id": "task_code"},
      {"source": "t", "id": "task_name"},
      {"source": "t", "id": "task_last_completed_date"},
      {"source": "t", "id": "task_url"}
    ]
  }
}
```

## KPI: Single number

```json
{
  "sources": [{"id": "t", "entity_type": "tasks"}],
  "columns": [],
  "base_filters": [
    {"source": "t", "id": "task_status", "type": "fixed_options", "value": {"options": [{"id": "Pending"}, {"id": "In Progress"}]}},
    {"source": "t", "id": "task_finish_plan_date", "type": "date", "value": {"lte": "CURDATE()"}}
  ],
  "aggregations": [{"function": "COUNT", "column": "*", "alias": "total_delayed"}],
  "visualization": {"type": "number", "config": {"value": "total_delayed", "label": "Delayed tasks"}}
}
```

## Stacked bar: Status by project

```json
{
  "sources": [{"id": "t", "entity_type": "tasks"}],
  "columns": [
    {"source": "t", "id": "project_name"},
    {"source": "t", "id": "task_status"}
  ],
  "interactive_filters": [
    {"source": "t", "id": "task_request_date", "type": "date", "label": "Period", "default": {"relative": "last_three_months"}}
  ],
  "group_by": ["`t`.`project_name`", "`t`.`task_status`"],
  "aggregations": [{"function": "COUNT", "column": "*", "alias": "total"}],
  "visualization": {"type": "stacked_bar", "config": {"x_axis": "project_name", "y_axis": ["total"], "group_by": "task_status"}}
}
```

## Dynamic filter using `content_type`

Use this pattern when you want the widget filter to behave like `datareport`, loading names and search results from `filteroptions` instead of `column_values`.

```json
{
  "sources": [{"id": "t", "entity_type": "tasks"}],
  "columns": [{"source": "t", "id": "task_name"}],
  "interactive_filters": [
    {
      "source": "t",
      "id": "project_code",
      "type": "options",
      "label": "Proyecto",
      "content_type": "project",
      "default": null
    },
    {
      "source": "t",
      "id": "workspace_code",
      "type": "options",
      "label": "Área de trabajo",
      "content_type": "operationalunit",
      "default": null
    }
  ],
  "group_by": ["`t`.`task_name`"],
  "aggregations": [{"function": "COUNT", "column": "*", "alias": "total"}],
  "order_by": ["total DESC"],
  "visualization": {"type": "bar", "config": {"x_axis": "task_name", "y_axis": ["total"]}}
}
```

## Line chart: Trend over time

```json
{
  "sources": [{"id": "t", "entity_type": "tasks"}],
  "columns": [],
  "computed_columns": [
    {"expression": "DATE_FORMAT(`t`.`task_last_completed_date`, '%Y-%m')", "alias": "month"}
  ],
  "base_filters": [
    {"source": "t", "id": "task_status", "type": "fixed_options", "value": {"options": [{"id": "Completed"}]}}
  ],
  "interactive_filters": [
    {"source": "t", "id": "task_last_completed_date", "type": "date", "label": "Period", "default": {"relative": "last_six_months"}}
  ],
  "group_by": ["month"],
  "aggregations": [{"function": "COUNT", "column": "*", "alias": "completed"}],
  "order_by": ["month ASC"],
  "visualization": {"type": "line", "config": {"x_axis": "month", "y_axis": ["completed"]}}
}
```

## Join: Sum of form answer values by project

Sum a numeric form field (entry index "1.8") across SOL projects. Uses `entry_answers` joined with `forms` on `form_code`.

The `form_template_code` filter is essential — `answer_index` is shared across all form templates, so the same index (e.g., "1.8") means completely different things in different templates. Without the template filter, the aggregation would mix unrelated data and produce incorrect results.

```json
{
  "sources": [
    {"id": "ea", "entity_type": "entry_answers"},
    {"id": "f", "entity_type": "forms"}
  ],
  "columns": [{"source": "f", "id": "project_name"}],
  "joins": [
    {"from": "ea", "to": "f", "type": "inner", "on": {"form_code": "form_code"}}
  ],
  "base_filters": [
    {"source": "ea", "id": "form_template_code", "type": "text", "value": "FT-00402"},
    {"source": "ea", "id": "answer_index", "type": "text", "value": "1.8"},
    {"source": "f", "id": "project_code", "type": "text_starts_with", "value": "SOL"}
  ],
  "interactive_filters": [
    {"source": "f", "id": "form_last_submitted_date", "type": "date", "label": "Period", "default": {"relative": "last_three_months"}}
  ],
  "computed_columns": [
    {"expression": "CAST(`ea`.`answer_value` AS DECIMAL(10,2))", "alias": "numeric_value"}
  ],
  "group_by": ["`f`.`project_name`"],
  "aggregations": [{"function": "SUM", "column": "numeric_value", "alias": "total_length"}],
  "order_by": ["total_length DESC"],
  "visualization": {"type": "bar", "config": {"x_axis": "project_name", "y_axis": ["total_length"]}},
  "drill_down": {
    "columns": [
      {"source": "f", "id": "form_code"},
      {"source": "f", "id": "form_name"},
      {"source": "ea", "id": "answer_value"},
      {"source": "f", "id": "form_url"}
    ]
  }
}
```

## Conditional aggregation: Multiple metrics in one chart

Compare two different answer_index values (e.g., designed vs consumed cable meters) side by side per project. Uses `SUM(CASE WHEN...)` to aggregate each metric separately.

```json
{
  "sources": [
    {"id": "ea", "entity_type": "entry_answers"},
    {"id": "f", "entity_type": "forms"}
  ],
  "columns": [{"source": "f", "id": "project_name"}],
  "joins": [
    {"from": "ea", "to": "f", "type": "inner", "on": {"form_code": "form_code"}}
  ],
  "base_filters": [
    {"source": "ea", "id": "form_template_code", "type": "text", "value": "FT-00402"},
    {"source": "f", "id": "project_code", "type": "text_starts_with", "value": "SOL"}
  ],
  "computed_columns": [
    {"expression": "CAST(`ea`.`answer_value` AS DECIMAL(10,2))", "alias": "numeric_value"}
  ],
  "group_by": ["`f`.`project_name`"],
  "aggregations": [
    {"function": "SUM", "expression": "CASE WHEN `ea`.`answer_index` = '1.9' THEN CAST(`ea`.`answer_value` AS DECIMAL(10,2)) ELSE 0 END", "alias": "designed"},
    {"function": "SUM", "expression": "CASE WHEN `ea`.`answer_index` = '1.8' THEN CAST(`ea`.`answer_value` AS DECIMAL(10,2)) ELSE 0 END", "alias": "consumed"}
  ],
  "order_by": ["designed DESC"],
  "visualization": {"type": "bar", "config": {"x_axis": "project_name", "y_axis": ["designed", "consumed"]}}
}
```
