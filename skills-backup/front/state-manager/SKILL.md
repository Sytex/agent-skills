---
name: state-manager
description: Create state manager classes for presentation layer. Use when asked to add state management, create state managers, or implement presentation logic with Angular signals.
---

# State Manager Implementation

You are creating a state manager for the presentation layer following Clean Architecture principles.

## Step 1: Gather Information

Ask the user for:

- **Feature name** (e.g., `credential-search`, `task-quick-add`, `user-window`)
- **Module name** (e.g., `credentials`, `tasks`, `users`)
- **State manager type**:
  - `search` - For search/list operations
  - `window` - For CRUD operations on single entity
  - `quick-add` - For create operations with dependent data loading

---

## Step 2: Determine Location

State managers are located in:

```
src/app/core/{module}/presentation/{feature-name}.state-manager.ts
```

**Examples:**
- `src/app/core/credentials/presentation/credential-search.state-manager.ts`
- `src/app/core/tasks/presentation/task-quick-add.state-manager.ts`
- `src/app/core/credentials/presentation/credential-window.state-manager.ts`

---

## Step 3: Choose Template

### Template A: Search State Manager

For listing/searching entities with filters.

```typescript
import { computed, inject, Injectable, signal } from '@angular/core';
import { EntityCollection } from '@sdk/domain';
import { SearchFilter } from '@sdk/presentation';
import { Search{Entities}Error, Search{Entities}Usecase } from '@core/{module}/application';
import { {Entity}, {Entity}SearchColumnField } from '@core/{module}/domain';

export interface {Feature}State {
  collection: EntityCollection<{Entity}> | null;
  isLoading: boolean;
  error: Search{Entities}Error | null;
}

export const INITIAL_{FEATURE}_STATE: {Feature}State = {
  collection: null,
  isLoading: false,
  error: null
};

@Injectable()
export class {Feature}StateManager {
  private readonly _search{Entities}Usecase = inject(Search{Entities}Usecase);

  private readonly _state = signal<{Feature}State>(INITIAL_{FEATURE}_STATE);

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
    this._state.set(INITIAL_{FEATURE}_STATE);
  }
}
```

---

### Template B: Window State Manager (CRUD)

For single entity operations (get, update, delete).

```typescript
import { computed, inject, Injectable, signal } from '@angular/core';
import { NotFoundError } from '@sdk/domain';
import {
  Delete{Entity}Error,
  Delete{Entity}Usecase,
  Get{Entity}Error,
  Get{Entity}Usecase,
  Update{Entity}Data,
  Update{Entity}Error,
  Update{Entity}Usecase
} from '@core/{module}/application';
import { {Entity} } from '@core/{module}/domain';

export interface {Feature}State {
  {entity}: {Entity} | null;
  isLoading: boolean;
  isUpdating: boolean;
  isDeleting: boolean;
  isDeleted: boolean;
  isNotFound: boolean;
  error: Get{Entity}Error | Update{Entity}Error | Delete{Entity}Error | null;
}

export const INITIAL_{FEATURE}_STATE: {Feature}State = {
  {entity}: null,
  isLoading: false,
  isUpdating: false,
  isDeleting: false,
  isDeleted: false,
  isNotFound: false,
  error: null
};

@Injectable()
export class {Feature}StateManager {
  private readonly _get{Entity}Usecase = inject(Get{Entity}Usecase);
  private readonly _update{Entity}Usecase = inject(Update{Entity}Usecase);
  private readonly _delete{Entity}Usecase = inject(Delete{Entity}Usecase);

  private readonly _state = signal<{Feature}State>(INITIAL_{FEATURE}_STATE);

  readonly {entity} = computed(() => this._state().{entity});
  readonly isLoading = computed(() => this._state().isLoading);
  readonly isUpdating = computed(() => this._state().isUpdating);
  readonly isDeleting = computed(() => this._state().isDeleting);
  readonly isDeleted = computed(() => this._state().isDeleted);
  readonly isNotFound = computed(() => this._state().isNotFound);
  readonly error = computed(() => this._state().error);

  async loadById(id: string): Promise<void> {
    this._state.update(s => ({ ...s, isLoading: true, error: null, isNotFound: false }));

    const result = await this._get{Entity}Usecase.execute(id);

    if (result.isFailure()) {
      const error = result.getFailure();
      const isNotFound = error instanceof NotFoundError;
      this._state.update(s => ({ ...s, isLoading: false, error, isNotFound }));
      return;
    }

    this._state.update(s => ({ ...s, isLoading: false, {entity}: result.getSuccess() }));
  }

  async update(id: string, data: Update{Entity}Data): Promise<void> {
    this._state.update(s => ({ ...s, isUpdating: true, error: null }));

    const result = await this._update{Entity}Usecase.execute(id, data);

    if (result.isFailure()) {
      this._state.update(s => ({ ...s, isUpdating: false, error: result.getFailure() }));
      return;
    }

    this._state.update(s => ({ ...s, isUpdating: false, {entity}: result.getSuccess() }));
  }

  async delete(id: string): Promise<void> {
    this._state.update(s => ({ ...s, isDeleting: true, error: null }));

    const result = await this._delete{Entity}Usecase.execute(id);

    if (result.isFailure()) {
      this._state.update(s => ({ ...s, isDeleting: false, error: result.getFailure() }));
      return;
    }

    this._state.update(s => ({ ...s, isDeleting: false, isDeleted: true }));
  }

  reset(): void {
    this._state.set(INITIAL_{FEATURE}_STATE);
  }
}
```

---

### Template C: Quick-Add State Manager

For create operations with dependent data loading.

```typescript
import { computed, inject, Injectable, signal } from '@angular/core';
import { Add{Entity}Error, Add{Entity}Usecase, {Entity}CreateParams } from '@core/{module}/application';
import { SearchGenericEntitiesUsecase } from '@core/generic-entities/application';
import { GenericEntity } from '@core/generic-entities/domain';
import { ContentType } from '@core/shared/domain';
import { {Entity} } from '@core/{module}/domain';

export interface {Feature}State {
  isCreating: boolean;
  isCreated: boolean;
  created{Entity}: {Entity} | null;

  isLoadingDependency1: boolean;
  dependency1Options: GenericEntity[];

  isLoadingDependency2: boolean;
  dependency2Options: GenericEntity[];

  error: Add{Entity}Error | null;
}

export const INITIAL_{FEATURE}_STATE: {Feature}State = {
  isCreating: false,
  isCreated: false,
  created{Entity}: null,

  isLoadingDependency1: false,
  dependency1Options: [],

  isLoadingDependency2: false,
  dependency2Options: [],

  error: null
};

@Injectable()
export class {Feature}StateManager {
  private readonly _add{Entity}Usecase = inject(Add{Entity}Usecase);
  private readonly _searchGenericEntitiesUsecase = inject(SearchGenericEntitiesUsecase);

  private readonly _state = signal<{Feature}State>(INITIAL_{FEATURE}_STATE);

  readonly isCreating = computed(() => this._state().isCreating);
  readonly isCreated = computed(() => this._state().isCreated);
  readonly created{Entity} = computed(() => this._state().created{Entity});

  readonly isLoadingDependency1 = computed(() => this._state().isLoadingDependency1);
  readonly dependency1Options = computed(() => this._state().dependency1Options);

  readonly isLoadingDependency2 = computed(() => this._state().isLoadingDependency2);
  readonly dependency2Options = computed(() => this._state().dependency2Options);

  readonly error = computed(() => this._state().error);

  async create(params: {Entity}CreateParams): Promise<void> {
    this._state.update(state => ({ ...state, isCreating: true, error: null }));

    const result = await this._add{Entity}Usecase.execute(params);

    if (result.isFailure()) {
      this._state.update(state => ({
        ...state,
        isCreating: false,
        error: result.getFailure()
      }));
      return;
    }

    this._state.update(state => ({
      ...state,
      isCreating: false,
      isCreated: true,
      created{Entity}: result.getSuccess()
    }));
  }

  async loadDependency1(searchText?: string): Promise<void> {
    this._state.update(state => ({ ...state, isLoadingDependency1: true }));

    const result = await this._searchGenericEntitiesUsecase.execute(
      searchText ?? '',
      ContentType.dependency1Type
    );

    if (result.isSuccess() && result.getSuccess().length > 0) {
      this._state.update(state => ({
        ...state,
        isLoadingDependency1: false,
        dependency1Options: result.getSuccess()
      }));
      return;
    }

    this._state.update(state => ({
      ...state,
      isLoadingDependency1: false,
      dependency1Options: []
    }));
  }

  reset(): void {
    this._state.set(INITIAL_{FEATURE}_STATE);
  }
}
```

---

## Step 4: Implementation Rules

### 4.1 Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| File | `{feature-name}.state-manager.ts` | `credential-search.state-manager.ts` |
| Class | `{FeatureName}StateManager` | `CredentialSearchStateManager` |
| State Interface | `{FeatureName}State` | `CredentialSearchState` |
| Initial State | `INITIAL_{FEATURE_NAME}_STATE` | `INITIAL_CREDENTIAL_SEARCH_STATE` |

### 4.2 Dependency Injection

Always use `inject()` function (not constructor injection):

```typescript
private readonly _searchUsecase = inject(SearchEntitiesUsecase);
private readonly _getUsecase = inject(GetEntityUsecase);
```

### 4.3 State Pattern

- **Private signal** holds mutable state
- **Public computed signals** expose read-only slices
- **Methods** update state via `_state.update()`

```typescript
private readonly _state = signal<State>(INITIAL_STATE);

readonly isLoading = computed(() => this._state().isLoading);
readonly items = computed(() => this._state().collection?.items ?? []);
```

### 4.4 Async Operation Pattern

Every async method follows this structure and **always returns `Promise<void>`**. Results are communicated exclusively through state changes (signals), never through return values.

**IMPORTANT**: Components must NEVER `await` state manager method calls. Calls are fire-and-forget, and all reactions to state changes must be handled via `effect()` or `computed()`.

```typescript
async operation(): Promise<void> {
  // 1. Set loading state
  this._state.update(s => ({ ...s, isLoading: true, error: null }));

  // 2. Execute usecase
  const result = await this._usecase.execute(params);

  // 3. Handle failure
  if (result.isFailure()) {
    this._state.update(s => ({ ...s, isLoading: false, error: result.getFailure() }));
    return;
  }

  // 4. Handle success
  this._state.update(s => ({ ...s, isLoading: false, data: result.getSuccess() }));
}
```

### 4.5 Reset Method

Always include a reset method:

```typescript
reset(): void {
  this._state.set(INITIAL_STATE);
}
```

---

## Step 5: Component Integration

### 5.1 Register in Component Providers

```typescript
@Component({
  selector: 'app-{feature}',
  templateUrl: './{feature}.component.html',
  providers: [
    {Feature}StateManager,
    // Required usecases
    Search{Entities}Usecase,
    // Repository binding
    { provide: {Entities}Repository, useClass: {Entities}RepositoryImpl }
  ]
})
export class {Feature}Component {
  readonly stateManager = inject({Feature}StateManager);
}
```

### 5.2 Reactive Pattern (effects)

Components NEVER `await` state manager calls. Instead, they fire-and-forget and react to state changes via `effect()`:

```typescript
constructor() {
  effect(() => {
    const error = this.stateManager.error();
    if (error && error !== this._previousError) {
      this._previousError = error;
      this._handleError(error);
    }
  });

  effect(() => {
    const isDeleted = this.stateManager.isDeleted();
    if (isDeleted) {
      this.closeWindow();
    }
  });
}

save(): void {
  this.stateManager.update(id, data);
}

delete(): void {
  this.stateManager.delete(id);
}
```

### 5.3 Template Usage

```html
@if (stateManager.isLoading()) {
  <app-spinner />
}

@if (stateManager.error()) {
  <app-error-message [error]="stateManager.error()" />
}

@for (item of stateManager.items(); track item.id) {
  <app-item [data]="item" />
}
```

---

## Step 6: Testing

Tests are located in:

```
src/app/test/core/{module}/presentation/{feature-name}.state-manager.spec.ts
```

### 6.1 Test Template: Search State Manager

```typescript
import { fakeAsync, TestBed, tick } from '@angular/core/testing';
import { MockService } from 'ng-mocks';
import { ConnectionError, EntityCollection, PermissionError, Result, ServerError } from '@sdk/domain';
import { SearchFilter } from '@sdk/index';
import { Search{Entities}Usecase } from '@core/{module}/application';
import { {Entity} } from '@core/{module}/domain';
import { {Feature}StateManager } from '@core/{module}/presentation';
import { CommonUseCaseError } from '@core/shared/application';

describe('{Feature}StateManager', () => {
  let stateManager: {Feature}StateManager;
  let mockSearch{Entities}Usecase: Search{Entities}Usecase;

  beforeEach(() => {
    mockSearch{Entities}Usecase = MockService(Search{Entities}Usecase);

    TestBed.configureTestingModule({
      providers: [
        {Feature}StateManager,
        { provide: Search{Entities}Usecase, useValue: mockSearch{Entities}Usecase }
      ]
    });

    stateManager = TestBed.inject({Feature}StateManager);
  });

  it('should have initial state', () => {
    expect(stateManager.collection()).toBeNull();
    expect(stateManager.isLoading()).toBeFalse();
    expect(stateManager.error()).toBeNull();
    expect(stateManager.items()).toEqual([]);
    expect(stateManager.count()).toBe(0);
  });

  it('should set isLoading to true when search is called', fakeAsync(() => {
    const filter: SearchFilter = { filters: [] };
    const collection: EntityCollection<{Entity}> = { count: 0, items: [] };
    const response = Result.success<CommonUseCaseError, EntityCollection<{Entity}>>(collection);

    mockSearch{Entities}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

    stateManager.search(filter);
    expect(stateManager.isLoading()).toBeTrue();

    tick();
    expect(stateManager.isLoading()).toBeFalse();
  }));

  it('should set collection on successful search', fakeAsync(() => {
    const filter: SearchFilter = { filters: [] };
    const entity = MockService({Entity});
    entity.id = 'entity-id';

    const collection: EntityCollection<{Entity}> = { count: 1, items: [entity] };
    const response = Result.success<CommonUseCaseError, EntityCollection<{Entity}>>(collection);

    mockSearch{Entities}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

    stateManager.search(filter);
    tick();

    expect(stateManager.collection()).toEqual(collection);
    expect(stateManager.items()).toEqual([entity]);
    expect(stateManager.count()).toBe(1);
    expect(stateManager.error()).toBeNull();
  }));

  it('should set error on ConnectionError', fakeAsync(() => {
    const filter: SearchFilter = { filters: [] };
    const connectionError = new ConnectionError();
    const response = Result.failure<CommonUseCaseError, EntityCollection<{Entity}>>(connectionError);

    mockSearch{Entities}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

    stateManager.search(filter);
    tick();

    expect(stateManager.error()).toBe(connectionError);
    expect(stateManager.isLoading()).toBeFalse();
  }));

  it('should set error on PermissionError', fakeAsync(() => {
    const filter: SearchFilter = { filters: [] };
    const permissionError = new PermissionError();
    const response = Result.failure<CommonUseCaseError, EntityCollection<{Entity}>>(permissionError);

    mockSearch{Entities}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

    stateManager.search(filter);
    tick();

    expect(stateManager.error()).toBe(permissionError);
    expect(stateManager.isLoading()).toBeFalse();
  }));

  it('should set error on ServerError', fakeAsync(() => {
    const filter: SearchFilter = { filters: [] };
    const serverError = new ServerError();
    const response = Result.failure<CommonUseCaseError, EntityCollection<{Entity}>>(serverError);

    mockSearch{Entities}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

    stateManager.search(filter);
    tick();

    expect(stateManager.error()).toBe(serverError);
    expect(stateManager.isLoading()).toBeFalse();
  }));

  it('should reset state to initial values', fakeAsync(() => {
    const filter: SearchFilter = { filters: [] };
    const entity = MockService({Entity});
    entity.id = 'entity-id';

    const collection: EntityCollection<{Entity}> = { count: 1, items: [entity] };
    const response = Result.success<CommonUseCaseError, EntityCollection<{Entity}>>(collection);

    mockSearch{Entities}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

    stateManager.search(filter);
    tick();

    expect(stateManager.collection()).not.toBeNull();

    stateManager.reset();

    expect(stateManager.collection()).toBeNull();
    expect(stateManager.isLoading()).toBeFalse();
    expect(stateManager.error()).toBeNull();
  }));
});
```

### 6.2 Test Template: Window State Manager

```typescript
import { fakeAsync, TestBed, tick } from '@angular/core/testing';
import { MockService } from 'ng-mocks';
import { ConnectionError, NotFoundError, PermissionError, Result, ServerError, VoidValue } from '@sdk/domain';
import {
  Delete{Entity}Usecase,
  Get{Entity}Usecase,
  Update{Entity}Usecase
} from '@core/{module}/application';
import { {Entity} } from '@core/{module}/domain';
import { {Feature}StateManager } from '@core/{module}/presentation';

describe('{Feature}StateManager', () => {
  let stateManager: {Feature}StateManager;
  let mockGet{Entity}Usecase: Get{Entity}Usecase;
  let mockUpdate{Entity}Usecase: Update{Entity}Usecase;
  let mockDelete{Entity}Usecase: Delete{Entity}Usecase;

  beforeEach(() => {
    mockGet{Entity}Usecase = MockService(Get{Entity}Usecase);
    mockUpdate{Entity}Usecase = MockService(Update{Entity}Usecase);
    mockDelete{Entity}Usecase = MockService(Delete{Entity}Usecase);

    TestBed.configureTestingModule({
      providers: [
        {Feature}StateManager,
        { provide: Get{Entity}Usecase, useValue: mockGet{Entity}Usecase },
        { provide: Update{Entity}Usecase, useValue: mockUpdate{Entity}Usecase },
        { provide: Delete{Entity}Usecase, useValue: mockDelete{Entity}Usecase }
      ]
    });

    stateManager = TestBed.inject({Feature}StateManager);
  });

  it('should have initial state', () => {
    expect(stateManager.{entity}()).toBeNull();
    expect(stateManager.isLoading()).toBeFalse();
    expect(stateManager.isUpdating()).toBeFalse();
    expect(stateManager.isDeleting()).toBeFalse();
    expect(stateManager.isDeleted()).toBeFalse();
    expect(stateManager.isNotFound()).toBeFalse();
    expect(stateManager.error()).toBeNull();
  });

  describe('loadById', () => {
    it('should load entity successfully', fakeAsync(() => {
      const entity = MockService({Entity});
      entity.id = 'entity-id';
      const response = Result.success(entity);

      mockGet{Entity}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

      stateManager.loadById('entity-id');
      expect(stateManager.isLoading()).toBeTrue();

      tick();

      expect(stateManager.{entity}()).toEqual(entity);
      expect(stateManager.isLoading()).toBeFalse();
      expect(stateManager.error()).toBeNull();
    }));

    it('should set isNotFound on NotFoundError', fakeAsync(() => {
      const response = Result.failure(new NotFoundError());

      mockGet{Entity}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

      stateManager.loadById('entity-id');
      tick();

      expect(stateManager.isNotFound()).toBeTrue();
      expect(stateManager.isLoading()).toBeFalse();
    }));
  });

  describe('update', () => {
    it('should update entity successfully', fakeAsync(() => {
      const entity = MockService({Entity});
      entity.id = 'entity-id';
      const response = Result.success(entity);

      mockUpdate{Entity}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

      stateManager.update('entity-id', {});
      expect(stateManager.isUpdating()).toBeTrue();

      tick();

      expect(stateManager.{entity}()).toEqual(entity);
      expect(stateManager.isUpdating()).toBeFalse();
      expect(stateManager.error()).toBeNull();
    }));

    it('should set error on failure', fakeAsync(() => {
      const response = Result.failure(new ServerError());

      mockUpdate{Entity}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

      stateManager.update('entity-id', {});
      tick();

      expect(stateManager.error()).toBeInstanceOf(ServerError);
      expect(stateManager.isUpdating()).toBeFalse();
    }));
  });

  describe('delete', () => {
    it('should delete entity successfully', fakeAsync(() => {
      const response = Result.success(VoidValue.create());

      mockDelete{Entity}Usecase.execute = jasmine.createSpy().and.returnValue(Promise.resolve(response));

      stateManager.delete('entity-id');
      expect(stateManager.isDeleting()).toBeTrue();

      tick();

      expect(stateManager.isDeleted()).toBeTrue();
      expect(stateManager.isDeleting()).toBeFalse();
      expect(stateManager.error()).toBeNull();
    }));
  });

  it('should reset state to initial values', () => {
    stateManager.reset();

    expect(stateManager.{entity}()).toBeNull();
    expect(stateManager.isLoading()).toBeFalse();
    expect(stateManager.error()).toBeNull();
  });
});
```

### 6.3 Test Rules

1. **Use `fakeAsync` and `tick`** for async operations
2. **Use `MockService` from ng-mocks** to create mock usecases
3. **Test initial state** - verify all signals have correct default values
4. **Test loading states** - verify `isLoading`/`isUpdating`/etc. toggle correctly
5. **Test success cases** - verify data is set correctly after successful operations
6. **Test error cases** - verify different error types are handled (ConnectionError, PermissionError, ServerError, NotFoundError)
7. **Test reset** - verify state returns to initial values

---

## Reference Files

**Search Pattern:**
- `src/app/core/credentials/presentation/credential-search.state-manager.ts`
- `src/app/test/core/projects/presentation/project-search.state-manager.spec.ts`

**Window/CRUD Pattern:**
- `src/app/core/credentials/presentation/credential-window.state-manager.ts`

**Quick-Add Pattern:**
- `src/app/core/clients/presentation/client-quick-add.state-manager.ts`
- `src/app/core/tasks/presentation/task-quick-add.state-manager.ts`

**Complex Pattern (subscriptions):**
- `src/app/core/user-status/presentation/user-avatar-status.state-manager.ts`
