---
name: code-generation
description: Generate code from example files with exact pattern replication. Use when asked to create new modules, components, or files based on existing examples.
---

# Code Generation from Examples

You are generating code by replicating patterns from example files. Follow a METHODICAL and SEQUENTIAL process.

## Core Principles

- **NEVER** invent or improvise structures, paths, interfaces, or types
- **NEVER** modify state management, event, or error handling patterns
- **NEVER** change method names or their visibility
- **ALWAYS** maintain the exact same structure as the example
- If missing information, **ASK** the user before continuing

---

## Phase 1: Analysis

**Goal**: Fully understand the example patterns before writing any code.

### Step 1.1: Read All Related Files

For each example file provided:

1. Read the complete file content
2. Identify the file type (entity, repository, usecase, component, etc.)
3. Note the directory location

### Step 1.2: Extract Patterns

For each class/interface, document:

- [ ] Class name and inheritance (`extends`, `implements`)
- [ ] Decorator configuration (`@Injectable()`, `@Component()`, etc.)
- [ ] All import paths (must be identical in new code)
- [ ] Constructor parameters (names, types, visibility)
- [ ] Public properties and their types
- [ ] Private properties (with `_` prefix) and their types
- [ ] Public methods (signatures and return types)
- [ ] Private methods (signatures and return types)
- [ ] Interface definitions (position: above or below class)

### Step 1.3: Identify Dependencies

- List all services/repositories injected
- Note provider patterns in components
- Identify barrel imports (`@core/...`, `@sdk/...`)

---

## Phase 2: Preparation

**Goal**: Plan the exact transformations needed.

### Step 2.1: Define Name Mappings

Create a transformation table:

| Example               | New                        |
| --------------------- | -------------------------- |
| Project               | {NewEntity}                |
| ProjectSearch         | {NewEntity}Search          |
| SearchProjectsUsecase | Search{NewEntities}Usecase |
| projects              | {newEntities}              |

### Step 2.2: Plan File Structure

List all files to create with their paths:

```
core/{module}/
├── domain/
│   └── {entity}.ts
├── application/
│   ├── repositories/{entity}.repository.ts
│   └── usecases/{action}.usecase.ts
├── infrastructure/
│   └── {entity}.repository.impl.ts
└── presentation/
    └── {entity}.state-manager.ts
```

### Step 2.3: Verify Understanding

Before proceeding, confirm:

- [ ] All example files have been read
- [ ] Name mappings are complete
- [ ] File structure is planned
- [ ] No missing information

If anything is unclear, **STOP and ASK** the user.

---

## Phase 3: Implementation

**Goal**: Create files with exact pattern replication.

### Step 3.1: Create Files in Order

Follow dependency order:

1. Domain entities (no dependencies)
2. Repository interfaces (depend on entities)
3. Use cases (depend on repositories)
4. Repository implementations (depend on interfaces)
5. State managers (depend on use cases)
6. Components (depend on state managers)

### Step 3.2: For Each File

1. Start with exact imports from example (update paths as needed)
2. Copy class structure exactly
3. Apply name transformations from Phase 2
4. Maintain method order: public props → private props → constructor → public methods → private methods
5. Keep interfaces in same position (above/below class)

### Step 3.3: Implementation Rules

- Copy import structure exactly, only change entity names
- Preserve all decorators and their configurations
- Keep same visibility modifiers (public/private)
- Maintain parameter order in methods
- Use same return types with transformed names

---

## Phase 4: Verification

**Goal**: Ensure new code matches example structure exactly.

### Step 4.1: Structure Check

For each created file, verify:

- [ ] Import count matches example
- [ ] Class extends/implements same base classes
- [ ] Same number of properties
- [ ] Same number of methods
- [ ] Method signatures match (with name transformations)
- [ ] Interfaces are in correct position

### Step 4.2: Pattern Check

- [ ] Decorators are identical
- [ ] Dependency injection follows same pattern
- [ ] Error handling matches example
- [ ] State management matches example

### Step 4.3: Consistency Check

If any discrepancy is found:

1. **STOP immediately**
2. Identify the specific discrepancy
3. Correct it before continuing
4. Re-verify

---

## Quick Reference: Common Patterns

### Entity Pattern

```typescript
export class {Entity} extends Entity {
  // properties

  constructor(params: {Entity}Params) {
    super(params.id);
    // assignments
  }

  copyWith(params: Partial<{Entity}Params>): {Entity} {
    return new {Entity}({ ...this._toParams(), ...params });
  }

  private _toParams(): {Entity}Params { ... }
}

interface {Entity}Params { ... }
```

### Use Case Pattern

```typescript
@Injectable()
export class {Action}Usecase {
  constructor(
    private _repository: {Entity}Repository,
    private _errorMapper: CommonUseCaseErrorMapper
  ) {}

  async execute(params): Promise<Result<{Action}Error, {Entity}>> {
    const result = await this._repository.method(params);
    if (result.isFailure()) {
      return Result.failure(this._errorMapper.map(result.getFailure()));
    }
    return result;
  }
}
```

### State Manager Pattern

```typescript
export interface {Name}State { ... }
export const INITIAL_{NAME}_STATE: {Name}State = { ... };

@Injectable()
export class {Name}StateManager {
  private readonly _state = signal<{Name}State>(INITIAL_{NAME}_STATE);

  readonly property = computed(() => this._state().property);

  async method(): Promise<void> { ... }

  reset(): void {
    this._state.set(INITIAL_{NAME}_STATE);
  }
}
```
