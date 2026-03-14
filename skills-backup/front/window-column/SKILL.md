---
name: window-column
description: Add column configurations with GraphQL fragments for search windows. Use when asked to add columns, configure GraphQL field selection, or set up dynamic column loading.
---

# Window Column Implementation

You are adding column configurations with GraphQL fragments for dynamic field selection in search windows.

## Step 1: Gather Information

Ask the user for:

- Entity name (e.g., `workflow`, `task`, `project`)
- List of columns with their GraphQL fragments

The user can provide columns in various formats:

**Simple fields:**
```
code
name
status
```

**Fields with nested data:**
```
status { id name color }
template { id code name }
```

**Fields nested under a parent (use `parentField:` prefix):**
```
parentField:project code name
parentField:project attributes { id name color }
parentField:project client { id name avatar }
```

**Optional extended fields (base vs extended versions):**
```
networkElement { id code description }
networkElementSites { id code description sites { id code name isPrimary } }
```

Or with explicit markers:
```
client:base { id code name avatar }
client:withAttributes { id code name avatar attributes { id name color } }
```

**Multi-level nested sub-entities (path notation):**
```
parentField:project.client address { city country postalCode }
```

Or:
```
path:project.client address { city country }
path:project.client.address coordinates { lat lng }
```

---

## Understanding Column Types

### Root-Level Fields

Simple fields that belong directly to the entity:

```typescript
code: { gql: 'code' },
name: { gql: 'name' },
status: { gql: 'status { id name color }' }
```

### Nested Fields (with parentField)

Fields that should be grouped under a parent object in the GraphQL query:

```typescript
project: { gql: 'code name', parentField: 'project' },
projectClient: { gql: 'client { id name }', parentField: 'project' },
projectManager: { gql: 'manager { id name avatar }', parentField: 'project' }
```

When these are selected, the builder generates:
```graphql
project {
  id
  code name
  client { id name }
  manager { id name avatar }
}
```

### Overlapping Fields

Some columns may target the same GraphQL field with different sub-selections. GraphQL automatically merges them:

```typescript
// Both target 'client' field - GraphQL merges the selections
client: { gql: 'client { id code name avatar }' },
clientAttribute: { gql: 'client { id code name avatar attributes { id name color } }' }
```

### Optional Extended Fields (Base vs Extended)

When a field has optional sub-entities that may or may not be needed, create separate column entries:

**Pattern:** `{field}` (base) and `{field}{SubEntity}` (extended)

```typescript
// Base version - just the network element
networkElement: {
  gql: `networkElement {
    id
    code
    description
  }`
},

// Extended version - includes optional sites sub-entity
networkElementSites: {
  gql: `networkElement {
    id
    code
    description
    sites {
      id
      code
      name
      isPrimary
    }
  }`
}
```

**User input format:**

```
networkElement { id code description }
networkElementSites { id code description sites { id code name isPrimary } }
```

Or more explicitly:

```
networkElement:base { id code description }
networkElement:withSites { id code description sites { id code name isPrimary } }
```

**When to use this pattern:**

- Loading sites/children is expensive and not always needed
- Different views need different levels of detail
- The sub-entity is optional in the domain model

**How GraphQL handles selection:**

| Selected Columns                        | Query Result                              |
|-----------------------------------------|-------------------------------------------|
| `networkElement` only                   | Basic fields only                         |
| `networkElementSites` only              | Full fields with sites                    |
| Both `networkElement` + `networkElementSites` | GraphQL merges → full fields with sites |

**Naming convention:**

| Base Column       | Extended Column          | Sub-Entity    |
|-------------------|--------------------------|---------------|
| `networkElement`  | `networkElementSites`    | `sites`       |
| `client`          | `clientAttribute`        | `attributes`  |
| `project`         | `projectWithManager`     | `manager`     |
| `task`            | `taskWithAssignments`    | `assignments` |

### Multi-Level Nested Sub-Entities

When a sub-entity has its own optional nested data (e.g., `project.client.address`), use path notation:

**User input format:**

```
parentField:project.client address { city country postalCode }
```

Or with explicit path:
```
path:project.client address { city country }
path:project.client.address coordinates { lat lng }
```

**Config structure:**

For deeply nested optional fields, flatten the path in the column name:

```typescript
// Level 1: project (grouped under project)
[EntitySearchColumnField.project]: {
  gql: 'code name',
  parentField: 'project'
},

// Level 2: project.client (grouped under project)
[EntitySearchColumnField.projectClient]: {
  gql: `client {
    id
    name
  }`,
  parentField: 'project'
},

// Level 3: project.client with address (still grouped under project, but includes nested address)
[EntitySearchColumnField.projectClientAddress]: {
  gql: `client {
    id
    name
    address {
      city
      country
      postalCode
    }
  }`,
  parentField: 'project'
}
```

**Naming convention for multi-level:**

| Path                      | Column Name             | parentField |
|---------------------------|-------------------------|-------------|
| `project`                 | `project`               | `project`   |
| `project.client`          | `projectClient`         | `project`   |
| `project.client.address`  | `projectClientAddress`  | `project`   |
| `project.manager.team`    | `projectManagerTeam`    | `project`   |

**Important:** The `parentField` always refers to the **first level** parent. The builder groups all fields with the same `parentField` together, and GraphQL merges the nested selections.

**Example query generated:**

For columns `[project, projectClient, projectClientAddress]`:

```graphql
project {
  id
  code name
  client {
    id
    name
  }
  client {
    id
    name
    address {
      city
      country
      postalCode
    }
  }
}
```

GraphQL merges the duplicate `client` selections into:

```graphql
project {
  id
  code name
  client {
    id
    name
    address {
      city
      country
      postalCode
    }
  }
}
```

---

## Step 2: Locate Config File

Find the entity's column config file:

```
src/app/core/{module}/infrastructure/gql-{entity}-search-column.config.ts
```

If it doesn't exist, create it (see Step 3).

---

## Step 3: Add/Create Column Config

### Create New Config File

```typescript
import { GqlColumnConfig } from '@sdk/domain';
import { {Entity}SearchColumnField } from '../domain/shared/{entity}-search-column-field';

export const {Entity}SearchColumnConfig: GqlColumnConfig<{Entity}SearchColumnField> = {
  // Root-level simple fields
  [{Entity}SearchColumnField.code]: {
    gql: 'code'
  },
  [{Entity}SearchColumnField.name]: {
    gql: 'name'
  },
  [{Entity}SearchColumnField.status]: {
    gql: `status {
    id
    name
    color
  }`
  },

  // Nested fields under project
  [{Entity}SearchColumnField.project]: {
    gql: 'code name',
    parentField: 'project'
  },
  [{Entity}SearchColumnField.projectClient]: {
    gql: `client {
      id
      name
      avatar
    }`,
    parentField: 'project'
  }
};
```

### Add to Existing Config

Add new entries alphabetically within their category (root fields, then nested by parent):

```typescript
[{Entity}SearchColumnField.newField]: {
  gql: 'newField { id name }'
},
```

---

## Step 4: Add to Column Field Enum

If adding a new column, add it to the enum in:

```
src/app/core/{module}/domain/shared/{entity}-search-column-field.ts
```

```typescript
export enum {Entity}SearchColumnField {
  // existing fields...
  newField = 'newField'  // Add alphabetically
}
```

---

## Step 5: Export Config

Add to infrastructure barrel file:

```
src/app/core/{module}/infrastructure/index.ts
```

```typescript
export * from './gql-{entity}-search-column.config';
```

---

## Step 6: Use in Repository

### Add Builder Property

```typescript
import { GqlColumnQueryBuilder } from '@sdk/infrastructure';
import { {Entity}SearchColumnConfig } from './gql-{entity}-search-column.config';

export class {Entity}RepositoryImpl {
  private _columnQueryBuilder = new GqlColumnQueryBuilder({Entity}SearchColumnConfig);

  private _getGqlSearchQuery(columns?: {Entity}SearchColumnField[]): string {
    return this._columnQueryBuilder.build(columns);
  }
}
```

### Build Query with Selected Columns

```typescript
async search(criteria: Criteria, columns?: {Entity}SearchColumnField[]) {
  const fields = this._columnQueryBuilder.build(columns);
  const query = `{
    entities${this._criteriaConverter.convert(criteria)} {
      results {
        ${fields}
      }
      totalCount
    }
  }`;
  // ... execute query
}
```

---

## Example: Adding Multiple Columns

**Input from user:**

```
code
name
status { id name color }
parentField:project code name
parentField:project client { id name avatar }
parentField:project manager { id fullName }
template { id code name }
```

**Generated config:**

```typescript
import { GqlColumnConfig } from '@sdk/domain';
import { EntitySearchColumnField } from '../domain/shared/entity-search-column-field';

export const EntitySearchColumnConfig: GqlColumnConfig<EntitySearchColumnField> = {
  // Root-level fields
  [EntitySearchColumnField.code]: {
    gql: 'code'
  },
  [EntitySearchColumnField.name]: {
    gql: 'name'
  },
  [EntitySearchColumnField.status]: {
    gql: `status {
    id
    name
    color
  }`
  },
  [EntitySearchColumnField.template]: {
    gql: `template {
    id
    code
    name
  }`
  },

  // Project nested fields
  [EntitySearchColumnField.project]: {
    gql: 'code name',
    parentField: 'project'
  },
  [EntitySearchColumnField.projectClient]: {
    gql: `client {
      id
      name
      avatar
    }`,
    parentField: 'project'
  },
  [EntitySearchColumnField.projectManager]: {
    gql: `manager {
      id
      fullName
    }`,
    parentField: 'project'
  }
};
```

---

## GqlColumnQueryBuilder Behavior

The builder:

1. **Always includes `id`** - The entity ID is always in the query
2. **Groups nested fields** - Fields with same `parentField` are grouped
3. **Includes all fields if none specified** - `build()` without args returns all columns
4. **Returns only `id` for empty array** - `build([])` returns just `id`

### Example Output

For `build([code, name, projectClient, projectManager])`:

```graphql
id
code
name
project {
  id
  client {
    id
    name
    avatar
  }
  manager {
    id
    fullName
  }
}
```

---

## Reference Files

- Types: `src/app/sdk/domain/gql-column-config.ts`
- Builder: `src/app/sdk/infrastructure/gql-column-query-builder.ts`
- Example config: `src/app/core/workflows/infrastructure/gql-workflow-search-column.config.ts`
- Example enum: `src/app/core/workflows/domain/shared/workflow-search-column-field.ts`
- Example repository: `src/app/core/workflows/infrastructure/workflows.repository.impl.ts`
