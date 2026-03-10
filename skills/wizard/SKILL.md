---
name: wizard
description: Generate Sytex wizard JSON configurations. Use when user asks to create a wizard, wizard JSON, or wants to automate object creation in Sytex with a step-by-step form.
allowed-tools:
  - Read
---

# Sytex Wizard JSON Generator

Generate wizard JSON configurations for Sytex. Wizards are step-by-step forms that collect user inputs and then create objects automatically.

## JSON Structure

A wizard JSON has two main sections: **steps** (with inputs) and **operations** (objects to create).

```json
{
  "steps": [
    {
      "name": "Step name",
      "hint": "Instructions for the user",
      "inputs": [ ... ]
    }
  ],
  "operations": [ ... ]
}
```

You can have multiple steps. Each step has a `name`, optional `hint`, and an array of `inputs`.

---

## Input Types

### Text (default)

```json
{
  "name": "client_id",
  "label": "Client ID"
}
```

### Number

```json
{
  "name": "latitude",
  "label": "Latitude",
  "type": "number"
}
```

### Date

```json
{
  "name": "plan_date",
  "label": "Plan date",
  "type": "date"
}
```

### Date and Time

Date and time must be two separate inputs. Then use a Code operation to concatenate them.

```json
{
  "name": "activity_date",
  "label": "Request date",
  "type": "date"
},
{
  "name": "activity_time",
  "label": "Time (format: hh:mm)"
}
```

Then in operations, concatenate with a Code operation:

```json
{
  "type": "Code",
  "name": "date_time",
  "label": "Date and time",
  "data": {
    "fecha": "input_data.activity_date",
    "hora": "input_data.activity_time"
  },
  "prefix": "{fecha} {hora}",
  "zero_padding": 0
}
```

### Options

```json
{
  "name": "activity_type",
  "label": "Activity type",
  "type": "options",
  "options": [
    {
      "label": "Maintenance",
      "value": {
        "tasktemplate": 545
      }
    },
    {
      "label": "Uninstallation",
      "value": {
        "tasktemplate": 544
      }
    }
  ]
}
```

Each option's `value` is an object with one or more properties. Reference them in operations as `input_data.<input_name>.<property>` (e.g., `input_data.activity_type.tasktemplate`).

### Related Object (autocomplete dropdown)

Searches an API endpoint and lets the user select an object. The `class` must have the **first letter capitalized**.

```json
{
  "name": "site",
  "label": "Site",
  "type": "related_object",
  "related_object": {
    "endpoint": "/api/site/ureduced/?paginate=true",
    "class": "Site"
  }
}
```

**Common related object endpoints:**

| Object | Endpoint | Class |
|--------|----------|-------|
| Site | `/api/site/ureduced/?paginate=true` | `Site` |
| Network Element | `/api/networkelement/ureduced/?paginate=true` | `NetworkElement` |
| Client | `/api/client/ureduced/?paginate=true` | `Client` |
| Staff | `/api/staff/ureduced/?paginate=true&is_inactive=false` | `Staff` |
| Role | `/api/role/ureduced/?paginate=true` | `Role` |
| Supplier | `/api/supplier/ureduced/?paginate=true` | `Supplier` |
| Country Division | `/api/countrydivision/?country=<country_id>` | `CountryDivision` |
| Task | `/api/task/ureduced/?paginate=true` | `Task` |
| WBS | `/api/workstructure/ureduced/?paginate=true` | `WorkStructure` |
| Project | `/api/project/ureduced/?paginate=true` | `Project` |
| Workspace | `/api/operationalunit/ureduced/?paginate=true` | `Operationalunit` |

**Useful endpoint filters:**

- `/?site_type_id=id1,id2,id3` — Filter by site type
- `/?ne_type=id1,id2,id3` — Filter by NE type
- `/?operational_unit=id1,id2,id3` — Filter by operational unit
- `/?code__icontains=text` — Code contains text (case insensitive)
- `/?code__istartswith=text` — Code starts with text (case insensitive)
- `/?id__in=id1,id2,id3` — Filter by IDs
- `/?is_inactive=false` — Exclude inactive staff/contacts

---

## Input Modifiers

### Optional input

```json
{
  "name": "parent_task",
  "label": "Parent task",
  "type": "related_object",
  "required": false,
  "related_object": { ... }
}
```

### Hidden input

Used when the input value comes from wizard context (e.g., launched from a task). The user doesn't see it.

```json
{
  "name": "ne_code",
  "label": "NE Code",
  "type": "related_object",
  "related_object": {
    "endpoint": "/api/networkelement/",
    "class": "NetworkElement"
  },
  "hidden": true
}
```

### Default value

For text inputs:

```json
{
  "name": "client_id",
  "label": "Client ID",
  "default": "pepito"
}
```

For related_object inputs:

```json
{
  "name": "site",
  "label": "Site",
  "type": "related_object",
  "default": {
    "id": 9497,
    "code": "SI-1234"
  },
  "related_object": { ... }
}
```

For options inputs (the default value must match one of the option values):

```json
{
  "name": "client",
  "label": "Client",
  "type": "options",
  "default": {
    "code_prefix": "01"
  },
  "options": [
    { "label": "Claro", "value": { "code_prefix": "06" } },
    { "label": "TIM", "value": { "code_prefix": "01" } }
  ]
}
```

### Dynamic filter between inputs (`$input` params)

A `related_object` can filter its results based on another `related_object` input's selected value. Uses `$input.<other_input_name>` which resolves to the `.id` of the selected object.

**Important:** The referenced input MUST be of type `related_object`.

```json
{
  "name": "project",
  "label": "Project",
  "type": "related_object",
  "related_object": {
    "endpoint": "/api/project/",
    "class": "Project"
  }
},
{
  "name": "sub_project",
  "label": "Sub project",
  "type": "related_object",
  "related_object": {
    "endpoint": "/api/subproject/",
    "class": "SubProject",
    "params": { "project": "$input.project" }
  }
}
```

When the user selects a project, the sub project dropdown automatically calls `/api/subproject/?project=<selected_project_id>`.

---

## Operations

Operations define the objects to create. They run sequentially and can reference:

- `input_data.<input_name>` — Direct input value (for text, number, date)
- `input_data.<input_name>.<property>` — Property from an options value or related object
- `created_objects.<operation_name>` — Object created by a previous operation
- `created_objects.<operation_name>.id` — ID of a previously created object
- `created_objects.<operation_name>.<field>` — Any field of a previously created object

### Create Site

```json
{
  "type": "Site",
  "name": "site",
  "label": "Site",
  "data": {
    "code": "input_data.site_code",
    "name": "input_data.site_name",
    "latitude": "input_data.latitude",
    "longitude": "input_data.longitude",
    "site_type": "input_data.site_type.type_id",
    "project": "input_data.project",
    "country_division": "input_data.state"
  }
}
```

### Create Network Element

Sites must be in an array `[]`. Can include multiple sites.

```json
{
  "type": "NetworkElement",
  "name": "network_element",
  "label": "Network Element",
  "data": {
    "code": "input_data.ne_code",
    "description": "input_data.description",
    "organization": 154,
    "sites": [
      "input_data.site1",
      "input_data.site2"
    ],
    "ne_type": "124"
  }
}
```

With coordinates:

```json
{
  "type": "NetworkElement",
  "name": "network_element",
  "label": "Network Element",
  "data": {
    "code": "input_data.ne_code",
    "ne_type": 321,
    "organization": 108,
    "networkelementcoordinates_set": [
      {
        "name": "Coordinates",
        "latitude": "input_data.latitude",
        "longitude": "input_data.longitude"
      }
    ]
  }
}
```

### Create Client

```json
{
  "type": "Client",
  "name": "client",
  "label": "Client",
  "data": {
    "name": "input_data.client_name",
    "client_type": 3,
    "latitude": "input_data.lat",
    "longitude": "input_data.long",
    "custom_fields": {
      "Field Name": "input_data.field_value"
    }
  }
}
```

### Create WBS (WorkStructure)

```json
{
  "type": "WorkStructure",
  "name": "workflow",
  "label": "Workflow",
  "data": {
    "project": 262,
    "template": 220,
    "network_element": "input_data.network_element.id",
    "site": "created_objects.site.id",
    "start_plan_date": "input_data.date",
    "assigned_staff": "input_data.assigned_staff",
    "assigned_supplier": "input_data.assigned_supplier",
    "late_start": 1
  }
}
```

### Create Task

Sites must be in an array `[]`.

```json
{
  "type": "Task",
  "name": "task",
  "label": "Task",
  "data": {
    "project": 1909,
    "task_template": 463,
    "assigned_staff": "input_data.staff.id",
    "code": "input_data.task_code",
    "plan_date": "input_data.date",
    "request_date": "input_data.date",
    "request_time": "input_data.time",
    "client": "input_data.client",
    "sites": ["created_objects.site.id"],
    "description": "created_objects.task_description",
    "parent": "input_data.parent_task.id",
    "predecessors": ["input_data.previous_task.id"],
    "work_structure": "input_data.wbs.id"
  }
}
```

### Create Form

Sites must be in an array `[]`.

```json
{
  "type": "Form",
  "name": "form",
  "label": "Form",
  "data": {
    "project": 392,
    "template": 662,
    "assigned_user": "input_data.staff.related_user_id",
    "sites": [{ "id": 76433 }],
    "plan_date": "input_data.date",
    "organization": 167
  }
}
```

### Create Project

```json
{
  "type": "Project",
  "name": "project",
  "label": "Project",
  "data": {
    "name": "input_data.name",
    "client": "input_data.client.id",
    "operational_unit": "input_data.operation_unit.id",
    "country": "input_data.country.id",
    "start_date": "input_data.start_date",
    "status": 1
  }
}
```

### Create NetworkElement-Site Relationship

```json
{
  "type": "NetworkElementSite",
  "name": "ne_site",
  "data": {
    "network_element": "input_data.ne_code.id",
    "site": "created_objects.site.id"
  }
}
```

### Create Code (concatenation / sequential)

Used to build codes from concatenated values, or generate sequential codes.

**Sequential code with zero padding:**

```json
{
  "type": "Code",
  "name": "site_full_code",
  "label": "Site Code",
  "data": {
    "segment_1": "input_data.country_code.code",
    "segment_3": "input_data.project.group_name"
  },
  "prefix": "{segment_3}-{segment_1}-",
  "zero_padding": 4
}
```

`zero_padding` defines the number of digits for the sequential number (stored in `utils_objectsequence` table). Set to `0` for pure concatenation without a sequential number.

**Text concatenation (no sequential):**

```json
{
  "type": "Code",
  "name": "description",
  "label": "Description",
  "data": {
    "dept": "input_data.department",
    "city": "input_data.city"
  },
  "prefix": "Department: {dept} - City: {city}",
  "zero_padding": 0
}
```

### Create Assignment (linked assignments from WBS)

```json
{
  "type": "Assignment",
  "name": "assignment",
  "label": "Assignment",
  "data": {
    "work_structure": "created_objects.workflow.id",
    "assignment": "created_objects.workflow.assignment_set.0.id",
    "assigned_object": "input_data.equipment"
  },
  "update_or_create": true
}
```

---

## Advanced Features

### `update_or_create`

If the object might already exist, use `update_or_create: true`. It will update the existing object instead of failing.

```json
{
  "type": "NetworkElement",
  "name": "network_element",
  "label": "OT",
  "data": {
    "code": "input_data.OT",
    "organization": 100,
    "ne_type": "5"
  },
  "update_or_create": true
}
```

### Custom Fields

Add custom fields to any created object inside the `data` block:

```json
{
  "type": "Task",
  "name": "task",
  "label": "Task",
  "data": {
    "task_template": 463,
    "custom_fields": {
      "Custom Field Name": "input_data.field_value",
      "Another Field": "created_objects.some_code"
    }
  }
}
```

Custom fields from a related object:

```json
"custom_fields": {
  "field_name": "input_data.ne_code.custom_fields.0.answer_preview"
}
```

**Note on date-time custom fields:** When the custom field type is "Date and Time", it may not always auto-fill. As a workaround, use a custom field of type "Entry" (text) instead — it will always be filled.

### `resolve` — Resolve a name to ID

Allows sending a text value (e.g., sub project name) and having the wizard look it up in the database to convert it to an ID.

```json
"operations": [
  {
    "type": "WorkStructure",
    "name": "workflow",
    "label": "Workflow",
    "data": {
      "project": "input_data.project.project_id",
      "template": "input_data.task_type.template_id",
      "sub_project": "input_data.task_type.sub_project_name"
    },
    "resolve": {
      "sub_project": {
        "model": "projects.SubProject",
        "by": "name",
        "with": { "project": "project" }
      }
    }
  }
]
```

- `model`: Django model in `"app.Model"` format
- `by`: field to search by
- `with`: additional filters using other already-resolved values from the same `data` block (optional)

### Assign to the wizard's triggering user

Create the object first, then update it with the creator's info in a second operation:

```json
{
  "type": "Task",
  "name": "task",
  "label": "Task",
  "data": {
    "project": 144741,
    "task_template": 742,
    "plan_date": "input_data.date"
  }
},
{
  "type": "Task",
  "name": "task2",
  "label": "Task",
  "data": {
    "code": "created_objects.task.code",
    "requested_by_user": "created_objects.task.who_created_id"
  },
  "update_or_create": true
}
```

To convert user ID to staff ID, use `get_creator_active_staff_id`:

```json
{
  "type": "WorkStructure",
  "name": "workflow2",
  "label": "Workflow",
  "data": {
    "code": "created_objects.workflow1.code",
    "assigned_staff": "created_objects.workflow1.get_creator_active_staff_id"
  },
  "update_or_create": true
}
```

### Wizard button inside a task (context variables)

When a wizard is triggered from within a task, context variables (like `ne_code`, `wbs_code`, `parent_task`) are passed automatically. Define them as hidden inputs:

```json
{
  "name": "ne_code",
  "label": "NE Code",
  "type": "related_object",
  "related_object": {
    "endpoint": "/api/networkelement/",
    "class": "NetworkElement"
  },
  "hidden": true
}
```

The wizard is attached to a **task template** — all tasks created from that template will show the wizard button.

### WBS assignment inheritance

Tasks created by template within a WBS must have the same assigners as the parent WBS.

If Sentry shows `Assignment.DoesNotExist`, it means the task assigner name doesn't match any WBS assigner name.

---

## Complete Example

A wizard that creates a candidate site from a task context:

```json
{
  "steps": [
    {
      "name": "Create new Candidate",
      "hint": "Fill in the following fields to create a Candidate Site",
      "inputs": [
        {
          "name": "site_code_suffix",
          "label": "Site Option",
          "type": "options",
          "options": [
            { "label": "A", "value": { "character": "A" } },
            { "label": "B", "value": { "character": "B" } }
          ]
        },
        {
          "name": "tipo_sitio",
          "label": "Site type",
          "type": "options",
          "options": [
            { "label": "Greenfield", "value": { "type_id": 34 } },
            { "label": "Rooftop", "value": { "type_id": 35 } }
          ]
        },
        {
          "name": "date_plan_sar",
          "label": "SAR plan date",
          "type": "date"
        },
        {
          "name": "date_plan_site",
          "label": "Site plan date",
          "type": "date"
        },
        {
          "name": "ne_code",
          "label": "NE Code",
          "type": "related_object",
          "related_object": {
            "endpoint": "/api/networkelement/",
            "class": "NetworkElement"
          },
          "hidden": true
        },
        {
          "name": "wbs_code",
          "label": "WBS Code",
          "type": "related_object",
          "related_object": {
            "endpoint": "/api/workstructure/",
            "class": "WorkStructure"
          },
          "hidden": true
        },
        {
          "name": "parent_task",
          "label": "Trigger task",
          "type": "related_object",
          "related_object": {
            "endpoint": "/api/task/",
            "class": "Task"
          },
          "hidden": true
        }
      ]
    }
  ],
  "operations": [
    {
      "type": "Site",
      "name": "site",
      "label": "Candidate Site",
      "data": {
        "code": "input_data.wbs_code.name",
        "code_suffix": "input_data.site_code_suffix.character",
        "name": "input_data.ne_code.name",
        "site_type": "input_data.tipo_sitio.type_id",
        "latitude": "input_data.ne_code.networkelementcoordinates_set.0.latitude",
        "longitude": "input_data.ne_code.networkelementcoordinates_set.0.longitude"
      }
    },
    {
      "type": "NetworkElementSite",
      "name": "network_element_site",
      "data": {
        "network_element": "input_data.ne_code.id",
        "site": "created_objects.site.id"
      }
    },
    {
      "type": "Task",
      "name": "requerimiento_sar",
      "label": "SAR Requirement",
      "data": {
        "task_template": 270,
        "complete_dependencies": false,
        "visible_predecessor_complete": false,
        "sites": ["created_objects.site.id"],
        "network_element": "input_data.ne_code.id",
        "plan_date": "input_data.date_plan_sar",
        "work_structure": "input_data.wbs_code.id",
        "predecessors": ["input_data.parent_task.id"],
        "status.id": 115
      }
    },
    {
      "type": "Task",
      "name": "requerimiento_candidate",
      "label": "Candidate Requirement",
      "data": {
        "task_template": 272,
        "sites": ["created_objects.site.id"],
        "network_element": "input_data.ne_code.id",
        "plan_date": "input_data.date_plan_site",
        "work_structure": "input_data.wbs_code.id",
        "predecessors": ["created_objects.requerimiento_sar.id"]
      }
    }
  ]
}
```

## When to Use

Activate this skill when the user:

- Asks to create a wizard or wizard JSON
- Wants to configure an automated form in Sytex
- Needs to generate JSON for creating objects through a wizard
- Asks about wizard inputs, operations, or configuration
- Wants to automate object creation with a step-by-step form

## Important Rules

1. **Always output valid JSON** — validate structure before presenting
2. **`class` in related_object must have first letter capitalized** (e.g., `"Site"`, not `"site"`)
3. **Sites in operations must be inside arrays** `[]` (for Task, NetworkElement, Form)
4. **Each operation `name` must be unique** — used to reference with `created_objects.<name>`
5. **Operations run sequentially** — later operations can reference earlier ones
6. **Ask the user for IDs** (project, template, ne_type, organization, etc.) when they are specific to their environment
7. **`zero_padding: 0`** means no sequential number (pure concatenation)
8. **Date-time custom fields** may not auto-fill; suggest using "Entry" type as workaround
