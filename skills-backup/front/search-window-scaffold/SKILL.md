---
name: search-window-scaffold
description: Create the complete folder structure and scaffolding files for a new search window. Use when asked to create a new search window, entity search, or search module from scratch.
---

# Search Window Scaffold

You are creating the complete scaffolding for a new search window following Clean Architecture principles.

## Overview

This skill creates **all necessary files** for a new search window:
- Domain layer (entities, enums)
- Application layer (repository interface, use case)
- Infrastructure layer (repository implementation, mappers, GraphQL configs, search configs)
- Presentation layer (state manager)
- UI layer (search window component)
- Test files

**Total: ~25-35 files** depending on entity complexity.

---

## Step 1: Gather Information

Ask the user for:

### Required Information

1. **Entity name** (singular, PascalCase): e.g., `Invoice`, `Material`, `Supplier`
2. **Module name** (plural, kebab-case): e.g., `invoices`, `materials`, `suppliers`
3. **Entity icon**: Icon for the entity
   - Used in: window header, menu items, filter chips, buttons
   - Format options:
     - FontAwesome: `['fal', 'file-invoice']` or `['fas', 'box']`
     - Custom stacked icon: `siClipboardFileInvoice` (from `@ui/icons/icons.module`)
   - Check available custom icons in `src/app/ui/icons/icons.module.ts`
4. **Entity color** (hex color): e.g., `#47c9bd`, `#ffd371`, `#9597e2`
   - Used in: entity-specific styling throughout the app (chips, badges, accents)
   - Will be added to `src/colors.scss` as `color-{entity}: {color}`
   - Common colors:
     - `#47c9bd` (teal) - tasks, projects, workflows
     - `#ffd371` (yellow) - budgets, quotations, purchase orders
     - `#9597e2` (purple) - materials, shipments
     - `#f49393` (pink) - clients, contacts, suppliers
     - `#fbac80` (orange) - engineering, network elements
     - `#607ee0` (blue) - sites
     - `#cc92f0` (violet) - staff, fleet members
5. **Entity fields** - List of searchable/displayable fields with their types:

```
Field format: fieldName:type:options
Types: string, number, date, boolean, status, entity, enum
Options: filter, sort, column (comma-separated)

Example:
code:string:filter,sort,column
name:string:filter,sort,column
status:status:filter,sort,column
client:entity:filter,column
startDate:date:filter,sort,column
priority:enum:filter,column
isActive:boolean:filter
```

6. **Related entities** (optional): Nested entities like `StatusInInvoice`, `ClientInInvoice`

### Optional Information

7. **GraphQL endpoint name**: Default is `{entities}` (e.g., `invoices`)
8. **API resource name**: Default is `{entity}` (e.g., `invoice`)
9. **Visualization modes**: Default is `list` only. Options: `list`, `board`, `calendar`, `map`, `timeline`

### Example Input

```
Entity name: Invoice
Module name: invoices
Icon: ['fal', 'file-invoice']  (or: siClipboardFileInvoice)
Color: #3B82F6
Fields:
  code:string:filter,sort,column
  name:string:filter,sort,column
  status:status:filter,sort,column
  client:entity:filter,column
  dueDate:date:filter,sort,column
  amount:number:sort,column
Related entities: StatusInInvoice, ClientInInvoice
```

### Common Icons Reference

| Entity Type | FontAwesome | Custom (si*) |
|-------------|-------------|--------------|
| Invoice/Bill | `['fal', 'file-invoice']` | `siClipboardFileInvoice` |
| Task/Work | `['fal', 'clipboard-list']` | `siClipboardRectangleList` |
| Workflow | `['fal', 'diagram-project']` | `siClipboardDiagramProject` |
| Material/Item | `['fal', 'box']` | `siClipboardBoxTaped` |
| Form/Document | `['fal', 'file-lines']` | `siClipboardClipboardList` |
| Report | `['fal', 'chart-column']` | `siClipboardFileChartColumn` |
| Maintenance | `['fal', 'wrench']` | `siClipboardWrench` |

---

## Step 2: Validate SavedViewContext

Check if the entity exists in `SavedViewContext` enum:

**File:** `src/app/core/saved-views/domain/shared/saved-view-context.ts`

If the entity doesn't exist, add it to the enum:

```typescript
export enum SavedViewContext {
  // ... existing entries
  {entity} = XX  // Next available number
}
```

---

## Step 3: Register Entity Color

Add the entity color to the global colors file:

**File:** `src/colors.scss`

Add the color variable in the `$vars` map (alphabetically sorted by entity name):

```scss
$vars: (
  // ... existing colors
  color-{entity}: {color},  // e.g., color-invoice: #47c9bd
  // ... more colors
);
```

This color will be available as CSS variable: `var(--syt-color-{entity})`

---

## Step 4: Create Folder Structure

Create the following directory structure:

```
src/app/core/{module}/
├── domain/
│   ├── shared/
│   │   ├── {entity}-search-column-field.ts
│   │   ├── {entity}-search-filter.ts        # Enum only
│   │   ├── {entity}-search-sort.ts          # Enum only
│   │   └── index.ts
│   ├── {entity}-search/
│   │   ├── {entity}-search.ts
│   │   ├── [related-entity]-in-{entity}-search.ts  (for each related entity)
│   │   └── index.ts
│   └── index.ts
├── application/
│   ├── repositories/
│   │   ├── {entities}.repository.ts
│   │   └── index.ts
│   ├── usecases/
│   │   ├── search-{entities}.usecase.ts
│   │   └── index.ts
│   └── index.ts
├── infrastructure/
│   ├── {entity}-search-filter.config.ts     # Config only (API/GQL mappings)
│   ├── {entity}-search-sort.config.ts       # Config only (API/GQL mappings)
│   ├── gql-{entity}-search-column.config.ts
│   ├── {entities}.repository.impl.ts
│   ├── {entity}-search.from-mapper.ts
│   └── index.ts
├── presentation/
│   ├── {entity}-search.state-manager.ts
│   └── index.ts
└── index.ts

src/app/ui/windows/{entity}-search-window/
├── {entity}-search-window.component.ts
├── {entity}-search-window.component.html
└── {entity}-search-window.component.scss

src/app/test/core/{module}/
├── presentation/
│   └── {entity}-search.state-manager.spec.ts
└── infrastructure/
    └── {entity}-search.from-mapper.spec.ts
```

---

## Step 5: Generate Domain Layer Files

### 5.1 Column Field Enum

**File:** `domain/shared/{entity}-search-column-field.ts`

```typescript
export enum {Entity}SearchColumnField {
  // Generate from fields with 'column' option
  {fieldName} = '{fieldName}',
}
```

### 5.2 Filter Enum (Domain)

**File:** `domain/shared/{entity}-search-filter.ts`

```typescript
export enum {Entity}SearchFilter {
  // Generate from fields with 'filter' option
  // Sort alphabetically
  {fieldName} = '{fieldName}',
  q = 'q',
}
```

### 5.3 Sort Enum (Domain)

**File:** `domain/shared/{entity}-search-sort.ts`

```typescript
export enum {Entity}SearchSort {
  // Generate from fields with 'sort' option
  {fieldName} = '{fieldName}',
}
```

### 5.4 Shared Index

**File:** `domain/shared/index.ts`

```typescript
export * from './{entity}-search-column-field';
export * from './{entity}-search-filter';
export * from './{entity}-search-sort';
```

### 5.5 Search Entity

**File:** `domain/{entity}-search/{entity}-search.ts`

```typescript
import { Entity } from '@sdk/domain';
// Import related entities
import { StatusIn{Entity}Search } from './status-in-{entity}-search';

export class {Entity}Search extends Entity {
  // Generate from all fields
  readonly {fieldName}: {type};
  readonly status?: StatusIn{Entity}Search;

  constructor(params: {Entity}SearchParams) {
    super(params.id);
    // Assign all fields
  }
}

interface {Entity}SearchParams {
  id: string;
  // All field params
}
```

### 5.6 Related Entities (if needed)

**File:** `domain/{entity}-search/status-in-{entity}-search.ts`

```typescript
export class StatusIn{Entity}Search {
  constructor(
    public readonly id: string,
    public readonly name: string,
    public readonly color: string
  ) {}
}
```

### 5.7 Search Entity Index

**File:** `domain/{entity}-search/index.ts`

```typescript
export * from './{entity}-search';
export * from './status-in-{entity}-search';
// Export other related entities
```

### 5.8 Domain Index

**File:** `domain/index.ts`

```typescript
export * from './shared';
export * from './{entity}-search';
```

---

## Step 6: Generate Application Layer Files

### 6.1 Repository Interface

**File:** `application/repositories/{entities}.repository.ts`

```typescript
import { Criteria, EntityCollection, Result } from '@sdk/domain';
import { CoreException } from '@sdk/domain';
import { {Entity}Search } from '@core/{module}/domain';
import { {Entity}SearchColumnField } from '@core/{module}/domain/shared/{entity}-search-column-field';

export abstract class {Entities}Repository {
  abstract search(
    criteria: Criteria,
    columns?: {Entity}SearchColumnField[]
  ): Promise<Result<CoreException, EntityCollection<{Entity}Search>>>;
}
```

### 6.2 Repository Index

**File:** `application/repositories/index.ts`

```typescript
export * from './{entities}.repository';
```

### 6.3 Search Use Case

**File:** `application/usecases/search-{entities}.usecase.ts`

```typescript
import { Injectable } from '@angular/core';
import { EntityCollection, Result } from '@sdk/domain';
import { SearchFilter } from '@sdk/presentation';
import { {Entities}Repository } from '@core/{module}/application/repositories';
import { {Entity}Search } from '@core/{module}/domain';
import { {Entity}SearchColumnField } from '@core/{module}/domain/shared/{entity}-search-column-field';
import { CommonUseCaseError, CommonUseCaseErrorMapper } from '@core/shared/application';
import { SearchFilterCriteriaMapper } from '@core/shared/infrastructure';

export type Search{Entities}Error = CommonUseCaseError;

@Injectable()
export class Search{Entities}Usecase {
  constructor(
    private _repository: {Entities}Repository,
    private _criteriaMapper: SearchFilterCriteriaMapper,
    private _errorMapper: CommonUseCaseErrorMapper
  ) {}

  async execute(
    filters: SearchFilter,
    columns?: {Entity}SearchColumnField[]
  ): Promise<Result<Search{Entities}Error, EntityCollection<{Entity}Search>>> {
    const criteria = this._criteriaMapper.toMap(filters);
    const result = await this._repository.search(criteria, columns);
    return result.fold(
      error => Result.failure(this._errorMapper.map(error)),
      success => Result.success(success)
    );
  }
}
```

### 6.4 Usecases Index

**File:** `application/usecases/index.ts`

```typescript
export * from './search-{entities}.usecase';
```

### 6.5 Application Index

**File:** `application/index.ts`

```typescript
export * from './repositories';
export * from './usecases';
```

---

## Step 7: Generate Infrastructure Layer Files

### 7.1 Filter Config (Infrastructure)

**File:** `infrastructure/{entity}-search-filter.config.ts`

```typescript
import { SearchFieldConfig } from '@sdk/domain';

export const {Entity}SearchFilterConfig = {
  // Generate from fields with 'filter' option
  // Sort alphabetically
  {fieldName}: { api: '{field_name}', gql: '{fieldName}' },
  q: { api: 'q', gql: 'q' },
} as const satisfies SearchFieldConfig<string>;
```

### 7.2 Sort Config (Infrastructure)

**File:** `infrastructure/{entity}-search-sort.config.ts`

```typescript
import { SearchFieldConfig } from '@sdk/domain';

export const {Entity}SearchSortConfig = {
  // Generate from fields with 'sort' option
  {fieldName}: { api: '{field_name}', gql: '{fieldName}' },
} as const satisfies SearchFieldConfig<string>;
```

### 7.3 GraphQL Column Config

**File:** `infrastructure/gql-{entity}-search-column.config.ts`

```typescript
import { GqlColumnConfig } from '@sdk/infrastructure';
import { {Entity}SearchColumnField } from '@core/{module}/domain/shared/{entity}-search-column-field';

export const {Entity}SearchColumnConfig: GqlColumnConfig<{Entity}SearchColumnField> = {
  // Generate from column fields
  [{Entity}SearchColumnField.{fieldName}]: {
    gql: '{fieldName}'
  },
  // For entity relations:
  [{Entity}SearchColumnField.status]: {
    gql: `status {
    id
    name
    color
  }`
  },
};
```

### 7.4 Repository Implementation

**File:** `infrastructure/{entities}.repository.impl.ts`

```typescript
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { Criteria, EntityCollection, Result } from '@sdk/domain';
import { GqlColumnQueryBuilder, GqlErrorParser } from '@sdk/infrastructure';
import { ConfigurableSearchFilterMapper } from '@sdk/infrastructure/configurable-search-filter.mapper';
import { ConfigurableSearchSortMapper } from '@sdk/infrastructure/configurable-search-sort.mapper';
import { {Entities}Repository } from '@core/{module}/application/repositories';
import { {Entity}Search } from '@core/{module}/domain';
import { {Entity}SearchColumnField } from '@core/{module}/domain/shared/{entity}-search-column-field';
import { ApiHelperImpl, GraphQlCriteriaConverter, GraphQlHelperImpl } from '@core/shared/infrastructure';
import { {Entity}SearchFilterConfig } from './{entity}-search-filter.config';
import { {Entity}SearchSortConfig } from './{entity}-search-sort.config';
import { {Entity}SearchColumnConfig } from './gql-{entity}-search-column.config';
import { {Entity}SearchFromMapper } from './{entity}-search.from-mapper';

@Injectable()
export class {Entities}RepositoryImpl implements {Entities}Repository {
  private _criteriaConverter: GraphQlCriteriaConverter;
  private _columnQueryBuilder: GqlColumnQueryBuilder<{Entity}SearchColumnField>;

  constructor(
    private _http: HttpClient,
    private _helper: ApiHelperImpl,
    private _gqlHelper: GraphQlHelperImpl,
    private _errorParser: GqlErrorParser,
    private _fromMapper: {Entity}SearchFromMapper
  ) {
    const filterMapper = new ConfigurableSearchFilterMapper({Entity}SearchFilterConfig, 'gql');
    const sortMapper = new ConfigurableSearchSortMapper({Entity}SearchSortConfig, 'gql');
    this._criteriaConverter = new GraphQlCriteriaConverter(filterMapper, sortMapper);
    this._columnQueryBuilder = new GqlColumnQueryBuilder({Entity}SearchColumnConfig);
  }

  async search(
    criteria: Criteria,
    columns?: {Entity}SearchColumnField[]
  ): Promise<Result<CoreException, EntityCollection<{Entity}Search>>> {
    const url = this._gqlHelper.getGraphQlUrl();
    try {
      const query = this._getSearchGraphQlQuery(criteria, columns);
      const result = await firstValueFrom(
        this._http.post<GqlResponse<Gql{Entity}SearchResponse>>(url, { query }, {
          headers: this._helper.getHeaders(),
          withCredentials: true
        })
      );

      if (result.errors) {
        const exception = this._errorParser.parse(result.errors);
        return Result.failure(exception);
      }

      const items = result.data.{entities}.edges.map(edge =>
        this._fromMapper.fromMap(edge.node)
      );
      const count = result.data.{entities}.totalCount;

      return Result.success({ items, count });
    } catch (error) {
      const exception = this._errorParser.parse(error);
      return Result.failure(exception);
    }
  }

  private _getSearchGraphQlQuery(criteria: Criteria, columns?: {Entity}SearchColumnField[]): string {
    const criteriaParams = this._criteriaConverter.convert(criteria);
    const columnsQuery = this._columnQueryBuilder.build(columns ?? []);

    return `query {
      {entities}(${criteriaParams}) {
        totalCount
        edges {
          node {
            id
            ${columnsQuery}
          }
        }
      }
    }`;
  }
}

interface Gql{Entity}SearchResponse {
  {entities}: {
    totalCount: number;
    edges: Array<{ node: Gql{Entity}SearchMap }>;
  };
}

interface Gql{Entity}SearchMap {
  id: string;
  // Add all mapped fields
}
```

### 7.5 From Mapper

**File:** `infrastructure/{entity}-search.from-mapper.ts`

```typescript
import { Injectable } from '@angular/core';
import { {Entity}Search } from '@core/{module}/domain';
import { StatusIn{Entity}Search } from '@core/{module}/domain/{entity}-search/status-in-{entity}-search';

@Injectable()
export class {Entity}SearchFromMapper {
  fromMap(map: Gql{Entity}SearchMap): {Entity}Search {
    return new {Entity}Search({
      id: map.id,
      // Map all fields
      status: map.status ? new StatusIn{Entity}Search(
        map.status.id,
        map.status.name,
        map.status.color
      ) : undefined,
    });
  }
}

export interface Gql{Entity}SearchMap {
  id: string;
  // All GraphQL response fields
}
```

### 7.6 Infrastructure Index

**File:** `infrastructure/index.ts`

```typescript
export * from './{entity}-search-filter.config';
export * from './{entity}-search-sort.config';
export * from './gql-{entity}-search-column.config';
export * from './{entities}.repository.impl';
export * from './{entity}-search.from-mapper';
```

---

## Step 8: Generate Presentation Layer Files

### 8.1 State Manager

**File:** `presentation/{entity}-search.state-manager.ts`

```typescript
import { computed, inject, Injectable, signal } from '@angular/core';
import { EntityCollection } from '@sdk/domain';
import { SearchFilter } from '@sdk/presentation';
import { Search{Entities}Error, Search{Entities}Usecase } from '@core/{module}/application';
import { {Entity}Search } from '@core/{module}/domain';
import { {Entity}SearchColumnField } from '@core/{module}/domain/shared/{entity}-search-column-field';

export interface {Entity}SearchState {
  collection: EntityCollection<{Entity}Search> | null;
  isLoading: boolean;
  error: Search{Entities}Error | null;
}

export const INITIAL_{ENTITY}_SEARCH_STATE: {Entity}SearchState = {
  collection: null,
  isLoading: false,
  error: null
};

@Injectable()
export class {Entity}SearchStateManager {
  private readonly _search{Entities}Usecase = inject(Search{Entities}Usecase);

  private readonly _state = signal<{Entity}SearchState>(INITIAL_{ENTITY}_SEARCH_STATE);

  readonly collection = computed(() => this._state().collection);
  readonly isLoading = computed(() => this._state().isLoading);
  readonly error = computed(() => this._state().error);
  readonly items = computed(() => this._state().collection?.items ?? []);
  readonly count = computed(() => this._state().collection?.count ?? 0);

  async search(filters: SearchFilter, columns?: {Entity}SearchColumnField[]): Promise<void> {
    this._state.update(s => ({ ...s, isLoading: true, error: null }));

    const result = await this._search{Entities}Usecase.execute(filters, columns);

    if (result.isFailure()) {
      this._state.update(s => ({ ...s, isLoading: false, error: result.getFailure() }));
      return;
    }

    this._state.update(s => ({ ...s, isLoading: false, collection: result.getSuccess() }));
  }

  reset(): void {
    this._state.set(INITIAL_{ENTITY}_SEARCH_STATE);
  }
}
```

### 8.2 Presentation Index

**File:** `presentation/index.ts`

```typescript
export * from './{entity}-search.state-manager';
```

---

## Step 9: Generate Module Index

**File:** `index.ts`

```typescript
export * from './domain';
export * from './application';
export * from './infrastructure';
export * from './presentation';
```

---

## Step 10: Register in Search Config Registry

**File:** `src/app/core/search/infrastructure/search-config.registrations.ts`

Add imports and registration:

```typescript
// {Entity}
import { {Entity}SearchFilterConfig } from '@core/{module}/infrastructure/{entity}-search-filter.config';
import { {Entity}SearchSortConfig } from '@core/{module}/infrastructure/{entity}-search-sort.config';
import { {Entity}SearchColumnConfig } from '@core/{module}/infrastructure/gql-{entity}-search-column.config';

// In SEARCH_CONFIGS array:
{
  context: SavedViewContext.{entity},
  config: {
    filter: {Entity}SearchFilterConfig,
    sort: {Entity}SearchSortConfig,
    column: {Entity}SearchColumnConfig
  }
},
```

---

## Step 11: Generate UI Component

### 11.1 Component TypeScript

**File:** `ui/windows/{entity}-search-window/{entity}-search-window.component.ts`

```typescript
import {
  ChangeDetectionStrategy,
  Component,
  effect,
  forwardRef,
  inject,
  OnDestroy,
  OnInit,
  ViewChild
} from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { FaIconComponent } from '@fortawesome/angular-fontawesome';
import { ConnectionError, PermissionError, ServerError } from '@sdk/domain';
import { SearchFilterItemOperator, SortDirectionMapper } from '@sdk/index';
import { AlertService } from '@sdk/infrastructure';
import { ConfigurableSearchFilterMapper } from '@sdk/infrastructure/configurable-search-filter.mapper';
import { AuthorizationsRepository, HasCreateAuthorizationUsecase } from '@core/authorizations/application';
import { ApiAuthorizationsRepository } from '@core/authorizations/infrastructure';
import { AuthorizationCubit } from '@core/authorizations/presentation';
import { GenericEntitySearchFilter, GenericEntitySearchSort } from '@core/generic-entities/domain';
import { OptionFilterContentType } from '@core/option-filters/domain';
import {
  {Entities}Repository,
  Search{Entities}Usecase
} from '@core/{module}/application';
import {
  {Entity}Search,
  {Entity}SearchColumnField,
  {Entity}SearchFilter,
  {Entity}SearchSort
} from '@core/{module}/domain';
import {
  {Entity}SearchFilterConfig,
  {Entities}RepositoryImpl,
  {Entity}SearchFromMapper
} from '@core/{module}/infrastructure';
import { {Entity}SearchStateManager } from '@core/{module}/presentation';
import { SavedViewsRepository } from '@core/saved-views/application/repositories';
import { GetTotalCountUsecase } from '@core/saved-views/application/usecases/get-total-count.usecase';
import { SavedViewContext } from '@core/saved-views/domain';
import { ApiSavedViewsRepository } from '@core/saved-views/infrastructure/api-saved-views.repository';
import { SavedViewsTotalCountCubit, SearchColumnsCubit } from '@core/saved-views/presentation';
import { ValidationError } from '@core/shared/application';
import { ContentType, SearchFilterItemType, SearchVisualizationMode } from '@core/shared/domain';
import {
  GenericEntityTriggersAddedState,
  GenericEntityTriggersCubit,
  GenericEntityTriggersDeletedState,
  GenericEntityTriggersUpdatedState
} from '@core/shared/presentation';
import { IframeUserStatusService, UserStatusService } from '@core/user-status/infrastructure';
import { RendererType } from '@shared/renderers';
import { WindowNavigateProvider } from '@shared/routing';
import { SearchWindow } from '@shared/search-window-component';
import { IconsModule } from '@ui/icons/icons.module';
import { ButtonComponent } from '@ui/shared/button/button.component';
import { ResultItem, ResultListComponent } from '@ui-shared/result-list/result-list.component';
import { SearchHeaderComponent } from '@ui-shared/search-header/search-header.component';
import { SearchWindowPaginatorComponent } from '@ui-shared/search-window-paginator/search-window-paginator.component';
import { ApiSearchFilterItemConverter } from '@ui-shared/helpers';

@Component({
  selector: 'app-{entity}-search-window',
  templateUrl: './{entity}-search-window.component.html',
  styleUrls: ['./{entity}-search-window.component.scss'],
  imports: [
    forwardRef(() => SearchHeaderComponent),
    FaIconComponent,
    IconsModule,
    ButtonComponent,
    ResultListComponent,
    SearchWindowPaginatorComponent
  ],
  providers: [
    AuthorizationCubit,
    HasCreateAuthorizationUsecase,
    { provide: AuthorizationsRepository, useClass: ApiAuthorizationsRepository },
    {Entity}SearchStateManager,
    Search{Entities}Usecase,
    {Entity}SearchFromMapper,
    { provide: {Entities}Repository, useClass: {Entities}RepositoryImpl },
    GetTotalCountUsecase,
    SavedViewsTotalCountCubit,
    { provide: SavedViewsRepository, useClass: ApiSavedViewsRepository },
    { provide: UserStatusService, useClass: IframeUserStatusService }
  ],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class {Entity}SearchWindowComponent extends SearchWindow implements OnInit, OnDestroy {
  private _triggersCubitUnsubscriber: () => void;
  private _searchFilterConverter: ApiSearchFilterItemConverter;
  private _previousError: unknown = null;
  private readonly _stateManager = inject({Entity}SearchStateManager);

  override qFilter = {Entity}SearchFilter.q;
  override savedViewContext = SavedViewContext.{entity};

  protected override _autoSearch = true;

  {entities}: {Entity}Search[] = [];

  @ViewChild(ResultListComponent) resultList?: ResultListComponent;

  constructor(
    protected override _activatedRoute: ActivatedRoute,
    protected override _authCubit: AuthorizationCubit,
    protected override _searchColumnsCubit: SearchColumnsCubit,
    protected override _sortDirectionMapper: SortDirectionMapper,
    protected override _windowNavigateProvider: WindowNavigateProvider,
    protected override _savedViewsTotalCountCubit: SavedViewsTotalCountCubit,
    private _triggersCubit: GenericEntityTriggersCubit,
    private _alertService: AlertService,
    private _userStatusService: UserStatusService
  ) {
    super();
    const searchFilterMapper = new ConfigurableSearchFilterMapper({Entity}SearchFilterConfig, 'api');
    this._searchFilterConverter = new ApiSearchFilterItemConverter(searchFilterMapper);
    this._setupStateEffects();
  }

  protected override get contentType(): ContentType {
    return ContentType.{entity};
  }

  protected override get objectName(): string {
    return $localize`{entity}`;
  }

  ngOnInit(): void {
    this._setTaskLabel();
    this._setSearchColumns();
    this._setWindowFilters();
    this._setVisualizationModes();
    this._initTriggersCubit();
    this._initGeneralCubits();
    this._getCreateAuthorization();
    this._userStatusService.startKeepAlive();
  }

  ngOnDestroy(): void {
    this._authCubitUnsubscriber?.();
    this._triggersCubit.destroy();
    this._triggersCubitUnsubscriber?.();
    this._searchColumnsCubitUnsubscriber?.();
    this._savedViewsTotalCountCubitUnsubscriber?.();
    this._userStatusService.stopKeepAlive();
  }

  override search(): void {
    if (this.visualizationMode.mode === SearchVisualizationMode.list) {
      const searchFilters = this._getSearchFilters();
      this.resultList?.scrollToTop();
      const columns = this.displayedColumns() as {Entity}SearchColumnField[];
      this._stateManager.search(searchFilters, columns);
      return;
    }
  }

  private _setupStateEffects(): void {
    effect(() => {
      const isLoading = this._stateManager.isLoading();
      if (isLoading) {
        this.searchPerformed.set(true);
      }
      this.loading.set(isLoading);
    });

    effect(() => {
      const error = this._stateManager.error();
      if (error && error !== this._previousError) {
        this._previousError = error;
        this._handleError(error);
      }
    });

    effect(() => {
      const items = this._stateManager.items();
      const count = this._stateManager.count();

      this.{entities} = [...items];
      this.resultCount = count;

      this.resultEntities.set(
        this.{entities}.map(entity => {
          const resultItem: ResultItem = {
            entity: entity,
            updating: false
          };
          return resultItem;
        })
      );
    });
  }

  private _initTriggersCubit(): void {
    this._triggersCubitUnsubscriber = this._triggersCubit.addChangeListener(changes => {
      if (changes.nextState instanceof GenericEntityTriggersAddedState) {
        this.search();
        return;
      }
      if (changes.nextState instanceof GenericEntityTriggersUpdatedState) {
        this.search();
        return;
      }
      if (changes.nextState instanceof GenericEntityTriggersDeletedState) {
        this.search();
        return;
      }
    });
    this._triggersCubit.initTriggers(ContentType.{entity});
  }

  private _getCreateAuthorization(): void {
    this._authCubit.hasCreateAuthorization(ContentType.{entity});
  }

  protected override _getTaskLabel(): string {
    const label = $localize`{Entities}`;

    if (this.selectedView) {
      return `<div>${label}</div><div>${this.selectedView.name}</div>`;
    }

    return label;
  }

  private _setSearchColumns(): void {
    this.columns = [
      // TODO: Add columns based on entity fields
    ];

    this._setDefaultDisplayedColumns();
    this._setSettingsColumns();
  }

  private _setDefaultDisplayedColumns(): void {
    this.displayedColumns.set([
      // TODO: Add default displayed columns
    ]);
  }

  private _setWindowFilters(): void {
    this.filters = [
      // TODO: Add filters based on entity fields
    ];
  }

  private _handleError(error: unknown): void {
    if (error instanceof ConnectionError) {
      this._alertService.send({
        title: $localize`Connection error`,
        message: new Map<string, string>().set('', $localize`Could not connect to the server.`)
      });
      return;
    }

    if (error instanceof PermissionError) {
      this._alertService.send({
        title: $localize`Permission error`,
        message: new Map<string, string>().set('', $localize`You do not have permission to search.`)
      });
      return;
    }

    if (error instanceof ServerError) {
      this._alertService.send({
        title: $localize`Server error`,
        message: new Map<string, string>().set('', $localize`An unexpected error occurred.`)
      });
      return;
    }

    if (error instanceof ValidationError) {
      this._alertService.send({
        title: $localize`Validation error`,
        message: error.errors
      });
      return;
    }
  }
}
```

### 11.2 Component Template

**File:** `ui/windows/{entity}-search-window/{entity}-search-window.component.html`

(Same as before - no changes needed for Clean Architecture)

### 11.3 Component Styles

**File:** `ui/windows/{entity}-search-window/{entity}-search-window.component.scss`

(Same as before - no changes needed for Clean Architecture)

---

## Step 12: Add Routing

**File:** `src/app/app.routes.ts`

Add route for the new search window:

```typescript
{
  path: '{entities}',
  loadComponent: () =>
    import('./ui/windows/{entity}-search-window/{entity}-search-window.component').then(
      m => m.{Entity}SearchWindowComponent
    )
},
```

---

## Step 13: Generate Test Files

### 13.1 State Manager Test

**File:** `test/core/{module}/presentation/{entity}-search.state-manager.spec.ts`

Use the template from the `state-manager` skill.

### 13.2 From Mapper Test

**File:** `test/core/{module}/infrastructure/{entity}-search.from-mapper.spec.ts`

```typescript
import { {Entity}SearchFromMapper } from '@core/{module}/infrastructure';

describe('{Entity}SearchFromMapper', () => {
  let mapper: {Entity}SearchFromMapper;

  beforeEach(() => {
    mapper = new {Entity}SearchFromMapper();
  });

  it('should map all fields correctly', () => {
    const map = {
      id: 'test-id',
      // Add test data for all fields
    };

    const result = mapper.fromMap(map);

    expect(result.id).toBe('test-id');
    // Add assertions for all fields
  });
});
```

---

## Summary Checklist

After running this skill, verify:

- [ ] SavedViewContext enum updated
- [ ] Entity color added to `src/colors.scss`
- [ ] Domain layer files created (enums in domain/shared)
- [ ] Application layer files created
- [ ] Infrastructure layer files created (configs in infrastructure)
- [ ] Presentation layer files created
- [ ] UI component files created
- [ ] Search config registry updated (imports from infrastructure)
- [ ] Route added
- [ ] Test files created

**Next Steps (Manual):**
1. Complete the `_setSearchColumns()` method with actual columns
2. Complete the `_setWindowFilters()` method with actual filters
3. Add entity to `ContentType` enum if needed
4. Add any missing related entity mappers
5. Run tests and fix any issues

---

## Reference Files

- Complete example: `src/app/core/projects/` (all layers)
- Enum example: `src/app/core/projects/domain/shared/project-search-filter.ts`
- Config example: `src/app/core/projects/infrastructure/project-search-filter.config.ts`
- Search window: `src/app/ui/windows/project-search-window/`
- State manager skill: `agents/skills/state-manager/SKILL.md`
- Window filter skill: `agents/skills/window-filter/SKILL.md`
- Window sort skill: `agents/skills/window-sort/SKILL.md`
- Window column skill: `agents/skills/window-column/SKILL.md`
