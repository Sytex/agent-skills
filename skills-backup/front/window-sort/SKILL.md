---
name: window-sort
description: Add sort parameters to search windows. Use when asked to add sorting options, modify search sort mappers, or configure sortable columns.
---

# Window Sort Implementation

You are adding a new sort parameter to a search window.

## Step 1: Gather Information

Ask the user for:

- Entity name (e.g., `task`, `project`)
- List of API field names (snake_case format)

The user can paste a list of fields like:

```
assigned_user
client__name
start_date
status
```

---

## Field Name Conversion Rules

Convert API field names (snake_case) to:

### Key Name (camelCase)

- Remove underscores and capitalize following letters
- `assigned_user` → `assignedUser`
- `start_date` → `startDate`
- For double underscores, treat as relation: `client__name` → `clientName`

### GraphQL Name

- Single underscore `_` → camelCase: `assigned_user` → `assignedUser`
- Double underscore `__` → single underscore + Capital: `client__name` → `client_Name`

### Examples

| API (snake_case)       | Key (camelCase)       | GraphQL                |
| ---------------------- | --------------------- | ---------------------- |
| `assigned_user`        | `assignedUser`        | `assignedUser`         |
| `start_date`           | `startDate`           | `startDate`            |
| `client__name`         | `clientName`          | `client_Name`          |
| `user__permission`     | `userPermission`      | `user_Permission`      |
| `status`               | `status`              | `status`               |

---

## Step 2: Locate Files

The sort configuration is split across two files following Clean Architecture:

**Enum (domain concept):**
```
src/app/core/{module}/domain/shared/{entity}-search-sort.ts
```

**Config (API/GQL mappings):**
```
src/app/core/{module}/infrastructure/{entity}-search-sort.config.ts
```

If they don't exist, create them (see Step 3).

---

## Step 3: Add Sort to Files

### 3.1 Edit the Enum file (Domain)

**File:** `domain/shared/{entity}-search-sort.ts`

```typescript
export enum ProjectSearchSort {
  // existing entries...
  newField = 'newField'  // Add this line (alphabetically)
}
```

### 3.2 Edit the Config file (Infrastructure)

**File:** `infrastructure/{entity}-search-sort.config.ts`

```typescript
import { SearchFieldConfig } from '@sdk/domain';

export const ProjectSearchSortConfig = {
  // existing sorts...
  newField: { api: 'new_field', gql: 'newField' },  // Add this line (alphabetically)
} as const satisfies SearchFieldConfig<string>;
```

**Important:** Keep fields sorted alphabetically by key name in both files.

That's it for the mapper! The `SearchConfigRegistry` automatically provides mappers.

---

## Step 4: Register in SearchConfigRegistry (If New Entity)

**Only needed if this is a new entity** not yet in the registry.

Edit `src/app/core/search/infrastructure/search-config.registrations.ts`:

### Add imports

```typescript
// {Entity}
import { {Entity}SearchFilterConfig } from '@core/{module}/infrastructure/{entity}-search-filter.config';
import { {Entity}SearchSortConfig } from '@core/{module}/infrastructure/{entity}-search-sort.config';
```

### Add to SEARCH_CONFIGS array

```typescript
// {Entity}
{
  context: SavedViewContext.{entity},
  config: { filter: {Entity}SearchFilterConfig, sort: {Entity}SearchSortConfig }
},
```

---

## Step 5: Add Sort to Column Definition

In the search window component, add sort to the column:

```typescript
import { EntitySearchSort } from '@core/{module}/domain';

private _setSearchColumns(): void {
  this.columns = [
    // existing columns...
    {
      header: $localize`New Field`,
      property: EntitySearchColumnField.newField,
      sort: EntitySearchSort.newField,  // Add sort here
      renderer: RendererType.text,
      value: (element: Entity): string => element.newField
    }
  ];
}
```

---

## Example: Adding Multiple Sorts

**Input from user:**

```
status
client
project_manager
start_date
finish_date
```

**Generated enum (domain/shared/{entity}-search-sort.ts):**

```typescript
export enum ProjectSearchSort {
  client = 'client',
  finishDate = 'finishDate',
  projectManager = 'projectManager',
  startDate = 'startDate',
  status = 'status'
}
```

**Generated config (infrastructure/{entity}-search-sort.config.ts):**

```typescript
import { SearchFieldConfig } from '@sdk/domain';

export const ProjectSearchSortConfig = {
  client: { api: 'client', gql: 'client' },
  finishDate: { api: 'finish_date', gql: 'finishDate' },
  projectManager: { api: 'project_manager', gql: 'projectManager' },
  startDate: { api: 'start_date', gql: 'startDate' },
  status: { api: 'status', gql: 'status' }
} as const satisfies SearchFieldConfig<string>;
```

---

## Using Sorts in Repositories

Repositories import config from infrastructure (local or via barrel):

```typescript
import { ConfigurableSearchSortMapper } from '@sdk/infrastructure/configurable-search-sort.mapper';
import { {Entity}SearchSortConfig } from './{entity}-search-sort.config';
// Or from barrel: import { {Entity}SearchSortConfig } from '@core/{module}/infrastructure';

constructor() {
  this._criteriaConverter = new ApiUrlParamCriteriaConverter(
    new ConfigurableSearchFilterMapper({Entity}SearchFilterConfig, 'api'),
    new ConfigurableSearchSortMapper({Entity}SearchSortConfig, 'api')
  );
}
```

Or via `SearchConfigRegistry` (for SavedViews):

```typescript
const sortMapper = this._searchConfigRegistry.getSortMapper(SavedViewContext.{entity});
```

---

## Reference Files

- Enum example: `src/app/core/projects/domain/shared/project-search-sort.ts`
- Config example: `src/app/core/projects/infrastructure/project-search-sort.config.ts`
- Registry: `src/app/core/search/infrastructure/search-config.registry.ts`
- Registrations: `src/app/core/search/infrastructure/search-config.registrations.ts`
- Generic mapper: `src/app/sdk/infrastructure/configurable-search-sort.mapper.ts`
- Types: `src/app/sdk/domain/search-field-config.ts`
