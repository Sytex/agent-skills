# FormTemplates

## Concepts

- **FormTemplate**: A reusable definition/blueprint that defines the structure, fields, and validation rules
- **Form**: An instance created from a FormTemplate, containing actual user-submitted data

Think of FormTemplate as a "blank form design" and Form as a "filled-out form".

## Creating FormTemplates

### Prerequisites

Before creating a FormTemplate, you need:
- **OperationalUnit ID** and/or **Project ID** (at least one is required)

**IMPORTANT**: If the user did NOT specify an OperationalUnit or Project, you MUST ask them which one to use. Do NOT choose one yourself.

If the user provides only a name or code (not ID), search for the ID:
```bash
# Search operational unit by name
~/.claude/skills/sytex/sytex get "/operationalunit/?q=<name>"

# Search project by name
~/.claude/skills/sytex/sytex projects --q "<name>"
```

### Step 1: Create the FormTemplate

```bash
~/.claude/skills/sytex/sytex post "/formtemplate/" '{
  "name": "Template Name",
  "operational_unit": {"id": 123},
  "project": {"id": 456}
}'
```

Either `operational_unit` or `project` can be omitted, but at least one is required.

### Step 2: Add entries (fields/questions)

**CRITICAL**: This is a PUT request - ALL fields from Step 1 response are REQUIRED or they will be erased. Copy the ENTIRE JSON response exactly as-is, then add only the `entries` field. Do NOT omit, simplify, or modify ANY field.

Example: If Step 1 returned:
```json
{
  "id": 6463,
  "code": "FT-06463",
  "name": "My Template",
  "operational_unit": {
    "id": 61,
    "code": "OU-0061",
    "name": "Demo FTTH",
    "avatar": "https://...",
    "_class": "operationalunit"
  },
  "project": null,
  ...
}
```

Then Step 2 must send the COMPLETE response + entries:
```bash
~/.claude/skills/sytex/sytex put "/formtemplate/6463/" '{
  "id": 6463,
  "code": "FT-06463",
  "name": "My Template",
  "operational_unit": {
    "id": 61,
    "code": "OU-0061",
    "name": "Demo FTTH",
    "avatar": "https://...",
    "_class": "operationalunit"
  },
  "project": null,
  ... all other fields exactly as received ...,
  "entries": [
    {
      "_class": "templateentrygroup",
      "name": "Section Name",
      "order": 1,
      "items": [
        {
          "_class": "templateentry",
          "label": "Field Label",
          "entry_type": 1,
          "mandatory": false,
          "order": 1
        }
      ]
    }
  ]
}'
```

**PUT replaces the entire resource. Any field you omit or simplify WILL BE LOST.**

### Step 3: Show the template URL

After successful creation, display the template URL to the user:

```
https://<subdomain>.sytex.io/o/<organization_id>/w/formtemplate-<template_id>
```

## Field Types (entry_type)

| ID | Type | Use for |
|----|------|---------|
| 1 | Input | Short text, names, codes |
| 2 | Date | Date/datetime fields |
| 3 | Textarea | Long descriptions, comments |
| 4 | Action | Photo/action field |
| 5 | Yes/No | Boolean questions |
| 6 | Options | Multiple choice selection |
| 7 | Location | GPS coordinates / geolocation |
| 8 | IP Address | IP address input |
| 9 | Code Scan | QR/barcode scanner |
| 10 | Multi-input | Multiple text inputs |
| 11 | File Upload | File attachment |
| 12 | Signature | Signature capture |
| 13 | Rating | Star rating |
| 14 | Object Selection | Select Sytex object (task, site, etc.) |
| 15 | Formula | Calculated field |
| 16 | Task Scope Progress | Task progress tracking |
| 17 | Fire Automation | Trigger automation |
| 100 | Repeat Start | Marker for repeatable group start |
| 101 | Repeat End | Marker for repeatable group end |

## Entry Structure

Every entry (group or field) requires:
- `id`: UUID (generate with `uuidgen` or similar)
- `index`: Hierarchical string ("1", "1.1", "1.2", "1.4.1", etc.)

### Group (templateentrygroup)
```json
{
  "id": "31b57c83-bac2-4490-97b1-1f0e02615d7f",
  "index": "1",
  "name": "Section Name",
  "order": 1,
  "_class": "templateentrygroup",
  "items": [...]
}
```

### Nested group (inside another group)
```json
{
  "id": "d49d3d33-5389-4133-bc78-1cecaef47853",
  "index": "1.4",
  "parent_group": "31b57c83-bac2-4490-97b1-1f0e02615d7f",
  "name": "Sub-section",
  "order": 4,
  "_class": "templateentrygroup",
  "items": [...]
}
```

### Field (templateentry)
```json
{
  "id": "0f9b628b-d2b0-4869-b5b7-92109afed96c",
  "index": "1.1",
  "entry_group": "31b57c83-bac2-4490-97b1-1f0e02615d7f",
  "entry_type": 1,
  "label": "Field Label",
  "indication": "Help text",
  "order": 1,
  "_class": "templateentry"
}
```

### Select/MultiSelect entry (with options)
```json
{
  "id": "6ea9e53c-7aa4-4b7f-abe2-33518a13110a",
  "index": "1.2",
  "entry_group": "31b57c83-bac2-4490-97b1-1f0e02615d7f",
  "entry_type": 4,
  "label": "Choose Option",
  "order": 2,
  "_class": "templateentry",
  "templateentryoption_set": [
    {"name": "Option 1", "code": "OPT1", "order": 1},
    {"name": "Option 2", "code": "OPT2", "order": 2}
  ]
}
```

### Repeatable group (for invoice items, checklists, etc.)

A repeatable group allows users to add multiple instances of the same fields. Requires 3 parts:

**1. The repeatable group itself:**
```json
{
  "id": "70c4d645-082e-45b9-a68e-12587c5b6ffa",
  "index": "1.6",
  "parent_group": "e55888cd-66a6-4faa-ba4d-e80f18586644",
  "name": "Team registration",
  "order": 6,
  "_class": "templateentrygroup",
  "allow_repeat": 1,
  "add_more_repeatable": 1,
  "initial_question": "How many technicians working today?",
  "item_name": "Technician",
  "quantity_input": 1,
  "show_as_table": 1,
  "items": [
    {
      "id": "1e0a04bf-74ee-4ab0-9399-b68f7c6d5628",
      "index": "1.6.1",
      "entry_group": "70c4d645-082e-45b9-a68e-12587c5b6ffa",
      "entry_type": 1,
      "label": "Name of technician",
      "order": 1,
      "_class": "templateentry"
    }
  ]
}
```

**2. Repeat start marker (entry_type 100):**
```json
{
  "id": "bf614a3d-8d0f-42e6-bccc-c6b28613e021",
  "index": "1.6",
  "entry_group": "e55888cd-66a6-4faa-ba4d-e80f18586644",
  "entry_type": 100,
  "label": "",
  "order": 6,
  "_class": "templateentry"
}
```

**3. Repeat end marker (entry_type 101):**
```json
{
  "id": "11a15146-c29d-45db-ba79-5ecc9673cd69",
  "index": "1.6-repeat-end",
  "entry_group": "e55888cd-66a6-4faa-ba4d-e80f18586644",
  "entry_type": 101,
  "label": "",
  "order": 7,
  "_class": "templateentry"
}
```

**Repeatable group fields:**
| Field | Description |
|-------|-------------|
| `allow_repeat` | 1 to enable repetition |
| `add_more_repeatable` | 1 to allow adding more instances |
| `initial_question` | Question shown to define quantity |
| `item_name` | Name for each instance (e.g., "Item", "Technician") |
| `quantity_input` | 1 to show quantity input |
| `show_as_table` | 1 to display as table (optional) |

## Guidelines

- Group related fields into sections (`templateentrygroup`)
- Use descriptive labels from the source document
- Set `mandatory: true` for required fields
- Generate unique codes (`UPPERCASE_WITH_UNDERSCORES`)
- Preserve field order from source
- Add `indication` for help text or instructions
- For select fields, extract all options with unique codes
