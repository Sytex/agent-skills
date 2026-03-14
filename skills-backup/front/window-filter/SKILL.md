---
name: window-filter
description: Add search filter parameters to search windows. Use when asked to add filters to entity search, modify search filter mappers, or configure window filters.
---

# Window Filter Implementation

You are adding a new search filter parameter to a search window.

## Step 1: Gather Information

Ask the user for:

- Entity name (e.g., `client`, `project`)
- List of API field names (snake_case format)

The user can paste a list of fields like:

```
assigned_user
client__attributes
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
- For double underscores, treat as relation: `client__attributes` → `clientAttribute`

### GraphQL Name

- Single underscore `_` → camelCase: `assigned_user` → `assignedUser`
- Double underscore `__` → single underscore + Capital: `client__attributes` → `client_Attributes`

### Examples

| API (snake_case)       | Key (camelCase)       | GraphQL                |
| ---------------------- | --------------------- | ---------------------- |
| `assigned_user`        | `assignedUser`        | `assignedUser`         |
| `start_date`           | `startDate`           | `startDate`            |
| `client__attributes`   | `clientAttribute`     | `client_Attributes`    |
| `user__permission`     | `userPermission`      | `user_Permission`      |
| `status`               | `status`              | `status`               |

---

## Step 2: Locate Files

The filter configuration is split across two files following Clean Architecture:

**Enum (domain concept):**
```
src/app/core/{module}/domain/shared/{entity}-search-filter.ts
```

**Config (API/GQL mappings):**
```
src/app/core/{module}/infrastructure/{entity}-search-filter.config.ts
```

If they don't exist, create them (see Step 3).

---

## Step 3: Add Filter to Files

### 3.1 Edit the Enum file (Domain)

**File:** `domain/shared/{entity}-search-filter.ts`

```typescript
export enum ProjectSearchFilter {
  // existing entries...
  newField = 'newField'  // Add this line (alphabetically)
}
```

### 3.2 Edit the Config file (Infrastructure)

**File:** `infrastructure/{entity}-search-filter.config.ts`

```typescript
import { SearchFieldConfig } from '@sdk/domain';

export const ProjectSearchFilterConfig = {
  // existing filters...
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

## Step 5: Update Search Window Component

Find the `_setWindowFilters` method and add the new filter:

```typescript
import { EntitySearchFilter } from '@core/{module}/domain';

private _setWindowFilters(): void {
  this.filters = [
    // existing filters...
    {
      icon: 'tag',
      label: $localize`New field`,
      name: EntitySearchFilter.newField,
      type: SearchFilterItemType.options,
      contentType: OptionFilterContentType.someType
    }
  ];
}
```

### Filter Types

| Type                              | Use Case                    |
| --------------------------------- | --------------------------- |
| `SearchFilterItemType.text`       | Free text input             |
| `SearchFilterItemType.options`    | Dropdown with options       |
| `SearchFilterItemType.date`       | Date picker                 |
| `SearchFilterItemType.boolean`    | Boolean toggle              |
| `SearchFilterItemType.fixedOptions` | Static dropdown options   |

---

## Example: Adding Multiple Filters

**Input from user:**

```
status
client
client__attributes
project_manager
start_date
```

**Generated enum (domain/shared/{entity}-search-filter.ts):**

```typescript
export enum ProjectSearchFilter {
  client = 'client',
  clientAttribute = 'clientAttribute',
  projectManager = 'projectManager',
  startDate = 'startDate',
  status = 'status'
}
```

**Generated config (infrastructure/{entity}-search-filter.config.ts):**

```typescript
import { SearchFieldConfig } from '@sdk/domain';

export const ProjectSearchFilterConfig = {
  client: { api: 'client', gql: 'client' },
  clientAttribute: { api: 'client__attributes', gql: 'client_Attributes' },
  projectManager: { api: 'project_manager', gql: 'projectManager' },
  startDate: { api: 'start_date', gql: 'startDate' },
  status: { api: 'status', gql: 'status' }
} as const satisfies SearchFieldConfig<string>;
```

---

## Using Filters in Repositories

Repositories import config from infrastructure (local or via barrel):

```typescript
import { ConfigurableSearchFilterMapper } from '@sdk/infrastructure/configurable-search-filter.mapper';
import { {Entity}SearchFilterConfig } from './{entity}-search-filter.config';
// Or from barrel: import { {Entity}SearchFilterConfig } from '@core/{module}/infrastructure';

constructor() {
  this._criteriaConverter = new ApiUrlParamCriteriaConverter(
    new ConfigurableSearchFilterMapper({Entity}SearchFilterConfig, 'api'),
    new ConfigurableSearchSortMapper({Entity}SearchSortConfig, 'api')
  );
}
```

Or via `SearchConfigRegistry` (for SavedViews):

```typescript
const filterMapper = this._searchConfigRegistry.getFilterMapper(SavedViewContext.{entity});
```

---

## Reference Files

- Enum example: `src/app/core/projects/domain/shared/project-search-filter.ts`
- Config example: `src/app/core/projects/infrastructure/project-search-filter.config.ts`
- Registry: `src/app/core/search/infrastructure/search-config.registry.ts`
- Registrations: `src/app/core/search/infrastructure/search-config.registrations.ts`
- Generic mapper: `src/app/sdk/infrastructure/configurable-search-filter.mapper.ts`
- Types: `src/app/sdk/domain/search-field-config.ts`
