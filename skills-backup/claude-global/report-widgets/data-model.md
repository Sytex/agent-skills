# Sytex Data Model

This document explains how data is structured in Sytex at a conceptual level. Use this to understand what you're querying. For exact column names and types, fetch the schema via `definition_schema`.

## Overview

Sytex is a field operations platform. The core hierarchy is:

```
Organization
└── Operational Unit (Workspace)
    └── Project
        └── Workflow (WorkStructure / WBS)
            └── Task
                ├── Form
                │   └── Entry Answers (the actual field data)
                ├── Task Documents
                ├── Task Scope Progress
                └── Stoppers (blockers)
```

Cross-cutting concerns:
- **Ubicaciones** (Sites, Network Elements, Clients) — assigned to tasks, forms, workflows, etc.
- **People** (Staff, Contacts, Suppliers) — assigned to tasks, forms, and other objects
- **Custom Fields** — dynamic fields on any entity
- **Materials & Inventory** — tracked through material operations
- **Procurement** — purchase orders and quotations

---

## Core Entities

### Projects

A project is a high-level initiative (e.g., "FTTH Córdoba Norte"). It has a code, name, client, country, dates, and a project manager. All work happens inside projects. Projects belong to an operational unit (workspace).

### Workflows (WorkStructures)

A workflow is a sequence of tasks within a project. It follows a template (WorkStructureTemplate) that defines the task structure. Workflows can be nested (parent-child). Each workflow is typically associated with one site or network element. Workflows have their own status tracking and milestone completion.

### Tasks

A task is a discrete unit of work. It belongs to a project and optionally to a workflow. Tasks are assigned to **staff** or a **supplier** (never both). They track:
- **Dates**: request, plan start/finish, actual start/finish, completion, availability
- **Status**: with a configurable status flow (org-specific values)
- **Priority** and **type**
- **Parent task**: tasks can be hierarchical

Tasks can have forms, documents, stoppers, and scope progress attached.

---

## Ubicaciones (Locations)

Sites, Network Elements, and Clients are collectively called **ubicaciones**. They are assigned to objects like tasks, forms, workflows, etc., providing the physical and organizational context.

### Sites

A physical location (e.g., a telecom tower, a building). Rich geographic data:
- Coordinates (latitude, longitude, elevation), address, country, region, zone, city
- Type, status, coverage area
- Ownership info, access control, security details
- Vertical structure data (height, type, EPA)
- Responsible people (regional, sub-regional, staff, legal, acquisition)

### Network Elements

Infrastructure assets (routers, antennas, switches, cables). Key traits:
- **Hierarchical**: parent-child tree structure (network topology)
- **Multi-site**: a network element can span multiple sites
- **Client-linked**: can be associated with clients
- Have a type, status, and attributes

### Clients

A company that receives services. Can be hierarchical (parent-child). Has contact info, contracts, tax data, and geographic location.

### How ubicaciones appear in the data warehouse

Since ubicaciones are assigned to objects, they show up as denormalized columns in multiple entities:
- `tasks`: `site_codes`, `site_names`, `client_name`, `network_element_code`
- `forms`: `site_codes`, `site_names`, `client_name`, `network_element_code`
- `entry_answers`: `site_codes`, `client_code`, `network_element_code`
- `workstructures`: `site_name`, `client_name`, `network_element_description`

This means you can filter/group by location **without joining** — the data is already denormalized.

**Note**: Objects can have multiple sites (M2M), stored as comma-separated values in `site_codes`/`site_names`.

---

## People & Identity

Understanding how users and people work in Sytex is important for interpreting assignment-related columns.

### User

The authentication identity. Has an email, a profile (name, avatar, personal data), and can belong to multiple organizations.

### Profile

Personal data attached to a User: name, email, phone, avatar, birth date, identification. The data warehouse resolves people to **email + name from the profile**.

### Staff

An internal employee within **one** organization. Linked to a User. Has a code (SF-xxxxx), area, position, start/leave dates, and a reporting hierarchy (reports_to). Staff are assigned to tasks as workers, supervisors, or responsible people.

### Contact

An external person (usually a supplier's employee) within **one** organization. Linked to a User. Has a code (CO-xxxxx). Contacts are linked to their parent entity (typically a Supplier) via a generic relation.

### Staff vs Contact: Key Rule

Within a single organization, a User is **either** Staff **or** Contact, **never both**. The same User can be Staff in Org A and Contact in Org B.

### Supplier

An external company that performs work. Suppliers have:
- A code (SU-xxxxx), name, legal name, status
- Contacts (their employees, represented as Contact records)
- Assignment to operational units (workspaces)

Suppliers are assigned to tasks, forms, purchase orders, and quotations.

### How people appear in the data warehouse

Depending on the object property, assignments may reference **User.id**, **Staff.id**, or **Contact.id**. However, in the data warehouse, all people are resolved to **email + name** pairs:

- Task fields: `task_assigned_staff_email`/`_name`, `task_supervisor_email`/`_name`, `task_assigned_supplier_name`
- Form fields: `form_assigned_user_email`/`_name`, `form_reviewer_user_email`/`_name`
- Most entities: `who_created_email`/`_name`, `who_last_edit_email`/`_name`

The `profiles` entity in the DW contains all Staff and Contacts unified, with a `person_type` column to distinguish them. It also includes `supplier` for contacts linked to a supplier.

---

## Forms (in depth)

Forms are the primary data collection mechanism. Understanding their structure is key for most reporting needs.

### Template → Instance

A **FormTemplate** defines the structure: what fields (entries) exist, in what groups, with what types. A **Form** is a filled instance of a template. One template produces many forms.

### Entry Groups

Fields are organized in **groups**. Groups can:
- **Nest**: A group can contain sub-groups
- **Repeat**: A group marked as "repeatable" can have multiple instances (e.g., "add another cable run"). Each repetition creates a new set of answers.

### Entries (Fields)

Each entry is a question/field within a group. Entry types include:
- **Text** (input, textarea)
- **Numeric** (number, rating)
- **Date**
- **Yes/No** (boolean)
- **Options** (dropdown, multi-select)
- **Photo** (camera capture with file attachments)
- **File upload**
- **Signature**
- **Location** (GPS coordinates)
- **Formula** (calculated from other entries)
- **Code scan** (barcode/QR)
- **Object selection** (reference to other Sytex entities)

### Hierarchical Indexing

Every entry answer has an **index** that encodes its position within the form hierarchy:

```
Group 1
├── Entry 1.1  (first entry in group 1)
├── Entry 1.2  (second entry)
├── ...
└── Entry 1.8  (eighth entry — e.g., "Longitud total cable")

Group 2 (repeatable)
├── Repetition 1
│   ├── Entry 2.1
│   └── Entry 2.2
├── Repetition 2
│   ├── Entry 2.1  (same index, different repetition)
│   └── Entry 2.2
```

The index format is `{group}.{entry}` or `{group}.{subgroup}.{entry}` for nested groups. For repeatable groups, the same index appears once per repetition.

**Key insight**: The `answer_index` identifies the _field_ (e.g., "1.8" = entry 8 in group 1). To get all values of that field across all forms, filter by `answer_index`. The index is stable across form instances of the same template.

### Entry Answers in the Data Warehouse

Each answer becomes **one row** in `entry_answers`. A form with 20 fields produces 20 rows. Key columns:

| Column | What it is |
|--------|-----------|
| `answer_index` | Hierarchical position (e.g., "1.8"). **Stable identifier** — use this for filtering. |
| `answer_entry_label` | Human-readable field name (e.g., "Longitud total cable"). Can vary by language/version. |
| `answer_entry_type` | Type of field (text, number, date, photo, etc.) |
| `answer_value` | The actual answer. **Always stored as TEXT**, even for numbers. Cast when aggregating. |
| `answer_group_name` | Name of the containing group |
| `answer_remarks` | User comments on this answer |
| `answer_status` | OK or IGNORED |
| `answer_approval_status` | APPROVED, REJECTED, or PENDING |

The row also carries denormalized context: `form_code`, `form_status`, `task_code`, `project_code`, `site_codes`, `client_code`, etc.

### Answer Files

File attachments from form entries (photos, documents, signatures). Each file is a separate row in `answer_files` with:
- The form and entry context (form_code, answer_index, entry_label)
- File metadata (name, MIME type, URL)
- GPS coordinates and timestamp of capture (useful for field verification)
- Uploader info

### Form Status Flow

Forms go through a status workflow. Status values are **org-specific** (language, custom flows), but common patterns:
- Draft → In Progress → Submitted → To Review → Approved / Rejected

**Never assume status values** — discover them via preview.

---

## Supporting Entities

### Custom Fields

Dynamic fields that attach to entities (tasks, workflows, quotations, site access requests). They have:
- A name, type, category, and value
- The `field_related_entity` column tells you what type of object the field belongs to
- `field_value` is always text (like `answer_value`)

Useful for org-specific data that doesn't fit the standard schema. Query the `custom_fields` entity and filter by `field_related_entity` and `field_name`.

### Status Histories

Status changes are tracked as separate entities:
- `task_status_histories`
- `form_status_histories`
- `quotation_status_histories`
- `simple_operation_status_histories`

Each row records:
- **What changed**: `status_from`, `status_to`, `status_field`
- **Who**: creator email and name
- **When**: creation date
- **Why**: comments
- **Where**: latitude/longitude (if action was geolocated)
- **Approval**: whether it was triggered by an approval process, step name, approved/rejected

Useful for reporting on SLAs, turnaround times, workflow compliance, and approval audit trails.

### Stoppers

Blockers or impediments that prevent task/workflow progress. They have:
- A code (ST-xx-xxxxx), name, description
- **Type** and **criticality** (Low, Medium, High)
- A status flow (open → resolved/closed)
- Links to task, workflow, and project
- Responsible person, due date, estimated resolution date
- Solution type and description (when resolved)

Use for reporting on blocking issues, resolution times, and bottleneck analysis.

### Materials & Inventory

Three related entities:

**Materials** — catalog items (equipment, antennas, cables, etc.):
- Code, name, type (Equipments, Antennas, Mountings, Miscellaneous, Structures, Spares, Furniture, Supplies, Cables)
- Physical properties (dimensions, weight, volume, diameter)
- Cost, manufacturer, measure unit
- Stock thresholds (safety stock, critical stock)

**Material Stocks** — inventory quantities at specific locations:
- Material reference, warehouse/site location
- Available quantity, reserved quantity
- Serial number tracking

**Simple Operations (Material Operations)** — inventory movements:
- Code, status, operation template, operation type
- Entry type (Entry, Movement, Return, Destruction, Site Inventory)
- Project and task context
- Responsible person and assigned supplier

**Simple Operation Items** — line items within operations:
- Material, quantity, serial numbers
- Origin and destination locations

### Procurement

**Purchase Orders** — commitments to buy from suppliers:
- Code, type, status, supplier
- Financial data: subtotal, tax, total, shipping cost, currency
- Timeline: delivery date, invoice date, pay date
- Links to projects, quotations, sites, network elements
- Item count and task completion tracking

**Purchase Order Items** — line items in POs

**Quotations** — price quotes with approval workflows:
- Code, name, type, status, supplier
- Item type, currency
- Links to project, task, network element, sites
- Custom fields specific to the quotation
- Approval tracking (approved/rejected/confirmed dates)

**Quotation Items** — line items in quotations

### Task Documents

Documents required at specific points during task execution:
- Required document code, type, and required status
- Current document status (tracks completion)
- Linked to task and workflow context
- Creation responsible info

### Task Scope Progress

Progress tracking against defined scopes within a task:
- Scope name, expected quantity, unit, cost
- Progress entries with quantity and date
- Progress percentage (calculated: progress / expected quantity)
- Can be triggered by form submissions (linked to entry answers)

### Site Access Requests

Requests for physical access to a site:
- Access window (from/to date and time)
- Site and client context
- Access type (defines approval rules)
- Requester and approval responsible
- Supplier performing the work
- Status flow for approval process

### Chat Metrics

Metrics about team attention cycles in Sytex's internal messaging:
- Chat context (title, related object)
- Team and requester info
- Response timing: first attention duration, total attention duration
- Message counts during attention cycle
- Resolution tracking (was attention properly closed)

### Profiles (Users)

Unified view of all people (Staff + Contacts) in the organization:
- Person type (Staff or Contact)
- Code, name, email, phone
- Position, area, reports to
- License and workspace info
- Supplier (for contacts linked to a supplier)
- Activity metrics (last login, weekly activity count)
- Active/inactive status

---

## Data Warehouse Patterns

### Denormalization

The data warehouse **denormalizes** relationships into each table. This means:

- `tasks` already has `project_name`, `site_codes`, `client_name`, etc. — no join needed
- `forms` already has `project_name`, `task_code`, `site_codes`, etc.
- `entry_answers` already has `form_code`, `project_code`, `task_code`, etc.

### M2M as Comma-Separated Values

Many-to-many relationships (e.g., a task with multiple sites) are stored as comma-separated strings: `site_codes = "SITE-001,SITE-002"`, `site_names = "Tower North,Tower South"`.

### When you DO need joins

- `entry_answers` → `forms`: To access form-level columns not in entry_answers (e.g., `form_name`, `template_name`). Join on `form_id = entity_id`.
- `forms` → `tasks`: To access task-level columns not in forms. Join on `task_id = entity_id`.

**Join keys**: Each entity has `entity_id` as its PK. Child entities have FK columns (e.g., `form_id`, `task_id`, `site_id`).

### Status Values Are Org-Specific

Status values for tasks, forms, workflows, stoppers, etc. are **configured per organization** — different languages, custom flows, different step names. **Never assume status values** — always discover them via preview first.

### All Text Values

`answer_value` and `custom_field_value` are always stored as TEXT. Cast to DECIMAL when doing numeric aggregations.

---

## Interpreting User Requests

| User says | What it means |
|-----------|--------------|
| _"Longitud total cable (1.8)"_ | An entry answer field. `(1.8)` is the `answer_index`. Discover the exact label with preview. |
| _"forms enviados"_ | Forms in "submitted" status. The exact value is org-specific — discover it. |
| _"proyectos que comienzan con SOL"_ | Filter `project_name` with `text_starts_with`. |
| _"apertura por proyecto"_ | `group_by` on `project_name`. |
| _"apertura por estado"_ | `group_by` on the status column. Usually means NOT filtering by a single status. |
| _"sumar el campo X"_ | `SUM` on `answer_value` with `CAST` to DECIMAL (it's stored as TEXT). |
| _"forms de la tarea X"_ | Filter `task_code` in forms or entry_answers. |
| _"por sitio"_ | Group by `site_codes` or `site_names`. |
| _"tareas atrasadas"_ | Tasks where `task_finish_plan_date` < today AND status is not completed. |
| _"tiempo de resolución"_ | Use status histories: `DATEDIFF` between status transitions. |
| _"materiales en stock"_ | Query `material_stocks` entity. |
| _"órdenes de compra pendientes"_ | Filter `purchase_orders` by status — discover status values first. |
| _"bloqueos abiertos"_ / _"stoppers"_ | Query `stoppers` entity, filter by open status. |
| _"quién completó más tareas"_ | Group by `task_assigned_staff_name` or `last_completed_user_name`, filter by completed status. |

## Discovery via Preview

Use the `preview` endpoint to explore data before creating a widget.

### Discover form field indexes and labels

```json
{
  "definition": {
    "sources": [{"id": "ea", "entity_type": "entry_answers"}, {"id": "f", "entity_type": "forms"}],
    "columns": [
      {"source": "ea", "id": "answer_index"},
      {"source": "ea", "id": "answer_entry_label"}
    ],
    "joins": [{"from": "ea", "to": "f", "type": "inner", "on": {"form_id": "entity_id"}}],
    "base_filters": [
      {"source": "f", "id": "project_name", "type": "text_starts_with", "value": "SOL"}
    ],
    "group_by": ["`ea`.`answer_index`", "`ea`.`answer_entry_label`"],
    "aggregations": [{"function": "COUNT", "column": "*", "alias": "count"}],
    "order_by": ["answer_index ASC"],
    "visualization": {"type": "table"}
  }
}
```

### Discover status values

```json
{
  "definition": {
    "sources": [{"id": "f", "entity_type": "forms"}],
    "columns": [{"source": "f", "id": "form_status"}],
    "group_by": ["`f`.`form_status`"],
    "aggregations": [{"function": "COUNT", "column": "*", "alias": "count"}],
    "visualization": {"type": "table"}
  }
}
```

### Discover project names

```json
{
  "definition": {
    "sources": [{"id": "f", "entity_type": "forms"}],
    "columns": [{"source": "f", "id": "project_name"}],
    "base_filters": [
      {"source": "f", "id": "project_name", "type": "text_starts_with", "value": "SOL"}
    ],
    "group_by": ["`f`.`project_name`"],
    "aggregations": [{"function": "COUNT", "column": "*", "alias": "count"}],
    "visualization": {"type": "table"}
  }
}
```

### Discover available columns for any entity

Always use `definition_schema` endpoint first to get exact column names. The examples above are patterns — adapt the entity type and columns to your needs.
