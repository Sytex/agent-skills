# FormTemplates

## Concepts

- **FormTemplate**: A reusable definition/blueprint that defines the structure, fields, and validation rules
- **Form**: An instance created from a FormTemplate, containing actual user-submitted data

Think of FormTemplate as a "blank form design" and Form as a "filled-out form".

## Creating FormTemplates from Files

When the user wants to create a FormTemplate from a file (XLS, PDF, image, etc.):

1. Read and analyze the source file
2. Identify fields, sections, and data types
3. Generate JSON following the structure below
4. POST to `/api/v1/formtemplate/import_template/`

## Field Types (entry_type)

| ID | Type | Use for |
|----|------|---------|
| 1 | Text | Short text, names, codes |
| 2 | Number | Quantities, measurements |
| 3 | TextArea | Long descriptions, comments |
| 4 | Select | Single choice from options |
| 5 | Yes/No | Boolean questions |
| 6 | MultiSelect | Multiple choices |
| 7 | Date | Date fields |
| 8 | Time | Time fields |
| 9 | Geolocation | GPS coordinates |
| 10 | Photo | Camera/image upload |
| 11 | Signature | Signature capture |
| 12 | File | File attachment |

## JSON Structure

```json
{
  "name": "Template Name",
  "code": "UNIQUE_CODE",
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
          "order": 1,
          "indication": "Help text"
        },
        {
          "_class": "templateentry",
          "label": "Selection Field",
          "entry_type": 4,
          "mandatory": true,
          "order": 2,
          "options": [
            {"name": "Option 1", "code": "OPT1", "order": 1},
            {"name": "Option 2", "code": "OPT2", "order": 2}
          ]
        }
      ]
    }
  ]
}
```

## Guidelines

- Group related fields into sections (`templateentrygroup`)
- Use descriptive labels from the source document
- Set `mandatory: true` for required fields
- Generate unique codes (`UPPERCASE_WITH_UNDERSCORES`)
- Preserve field order from source
- Add `indication` for help text or instructions
- For select fields, extract all options with unique codes

## Example: Create FormTemplate

```bash
~/.claude/skills/sytex/scripts/api.sh post "/v1/formtemplate/import_template/" '{
  "name": "Site Inspection",
  "code": "SITE_INSPECTION_001",
  "entries": [
    {
      "_class": "templateentrygroup",
      "name": "General Info",
      "order": 1,
      "items": [
        {"_class": "templateentry", "label": "Inspector Name", "entry_type": 1, "mandatory": true, "order": 1},
        {"_class": "templateentry", "label": "Inspection Date", "entry_type": 7, "mandatory": true, "order": 2}
      ]
    }
  ]
}'
```
