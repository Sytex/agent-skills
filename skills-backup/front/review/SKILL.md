---
name: review
description: Code review and standards enforcement for Sytex Angular frontend. Use when asked to review code in a folder, file, branch changes, or pull request. Validates code against project standards and offers to fix violations.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*), Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh api:*), Bash(find:*), Edit, Task, TaskCreate, TaskUpdate, TaskList, TaskGet, TeamCreate, TeamDelete, SendMessage
argument-hint: [path | branch | pr <number>]
---

# Code Review and Standards Enforcement

You are performing a code review to ensure compliance with Sytex frontend standards.

## Standards Reference

Read the complete standards from `agents/standards/standards.md` before reviewing.

## Input Modes

Determine the review mode based on `$ARGUMENTS`:

| Input                           | Mode          | Action                                   |
| ------------------------------- | ------------- | ---------------------------------------- |
| File/folder path                | Path Review   | Review all .ts/.html/.scss files in path |
| `branch` or `changes`           | Branch Review | Review files changed vs master           |
| `pr <number>` or `PR #<number>` | PR Review     | Review files changed in the PR           |

---

## Execution Strategy: Always Parallel

Split the review into 4 areas and run them **all in parallel**:

| Area | Scope |
|------|-------|
| Architecture, use cases & exception handling | TS: architecture, use cases, errors, exception handling, Result pattern |
| Naming, structure & code style | TS: naming, constants, method order, computed vs getters, magic strings, `any` type, barrel files |
| HTML, SCSS & i18n | HTML elements, button classes, i18n attributes, SCSS colors, spacing, radius, transitions, typography |
| Testing coverage | Missing .spec.ts files for new usecases, state managers, repos, mappers |

### If Agent Teams is available

1. Create a team named `review-{context}` (e.g., `review-pr-584`)
2. Create 4 tasks (one per area)
3. Spawn 4 agents simultaneously (`arch-reviewer`, `style-reviewer`, `html-reviewer`, `test-reviewer`) with `run_in_background: true` and `team_name`
4. Each agent reads `agents/standards/standards.md` first, gets the diff, checks its area, reports violations, marks task completed
5. Compile results, shutdown agents, delete team, present report

### If Agent Teams is NOT available

1. Fetch the full diff first (single call)
2. Spawn 4 `Task` agents in parallel (one per area) with `run_in_background: true` — no team, just parallel Task calls
3. Each agent gets the diff command, reads standards, checks its area, reports violations
4. Compile all results into the final report

---

## Gather Files to Review

**For Path (default):**

```bash
find $ARGUMENTS -type f \( -name "*.ts" -o -name "*.html" -o -name "*.scss" \) | head -100
```

**For Branch:**

```bash
git diff master --name-only --diff-filter=ACMR | grep -E '\.(ts|html|scss)$'
```

**For PR:**

```bash
gh pr diff <number> --name-only | grep -E '\.(ts|html|scss)$'
```

---

## Review Checklist by File Type

### TypeScript Files (\*.ts)

#### Architecture

- [ ] No `providedIn: 'root'` in `@Injectable()` (exception: stateless mappers)
- [ ] Correct layer placement (domain/application/infrastructure/presentation)
- [ ] Components do NOT inject repositories directly (use State Manager + Use Case)
- [ ] Result pattern: `Result<Error, Data>` or `Observable<Result<...>>`

#### Repositories & Mappers

- [ ] Repository implementations have corresponding test file in `test/` directory
- [ ] Mapper implementations have corresponding test file in `test/` directory

#### Naming

- [ ] File name: `{name}.{type}.ts` (usecase, repository, cubit, state-manager, component, etc.)
- [ ] Classes: PascalCase
- [ ] Private members: `_camelCase` prefix
- [ ] Constants: camelCase (NOT UPPER_CASE)
- [ ] API interfaces: `Api` prefix (`ApiUser`, `ApiResponse`)

#### Structure

- [ ] Method order: public props → private props → constructor → public methods → private methods
- [ ] Interfaces BELOW class definition
- [ ] Complex types extracted to named interfaces

#### Components

- [ ] `ChangeDetectionStrategy.OnPush` present
- [ ] Using `signal()` for reactive state (not `markForCheck()`)
- [ ] `computed()` instead of getters
- [ ] `effect()` instead of setters/ngOnChanges
- [ ] All dependencies in `providers` array
- [ ] Lifecycle interfaces implemented

#### State Managers

- [ ] **Uses StateManager pattern** (NOT Cubit from blac library)
- [ ] State interface exported
- [ ] Initial state constant exported
- [ ] `_state` NOT exposed directly (use `computed()`)
- [ ] Only emits domain entities (not UI objects)
- [ ] Has `reset()` method
- [ ] Has corresponding test file in `test/` directory

#### Use Cases

- [ ] Single `execute()` method
- [ ] Returns `Result<CustomError, Entity>`
- [ ] Uses `CommonUseCaseError` type alias (NOT specific error classes per use case)
- [ ] Injects `CommonUseCaseErrorMapper` for exception mapping
- [ ] Has corresponding test file in `test/` directory

#### Entities

- [ ] Extends `Entity` base class
- [ ] Has `copyWith()` method
- [ ] Uses `DateTime` for dates (not `string` or `Date`)

#### Errors

- [ ] Uses `CommonUseCaseError` type alias (NOT specific error classes per use case)
- [ ] Injects `CommonUseCaseErrorMapper` for exception mapping
- [ ] UI handles errors with `instanceof` checks on base classes (`ConnectionError`, `ServerError`, etc.)

#### Exception Handling

- [ ] No "just in case" try/catch blocks
- [ ] try/catch only for specific known exceptions (e.g., `SyntaxError` from `JSON.parse`)
- [ ] Unexpected exceptions are re-thrown

#### Code Style

- [ ] Curly brackets on ALL if/for/while (even single-line)
- [ ] No magic strings or numbers (use named constants or enums)
- [ ] No `any` type usage (define proper interfaces)
- [ ] No unused imports
- [ ] Barrel files (index.ts) updated for new files

### HTML Files (\*.html)

- [ ] No `<p>`, `<h1>`-`<h6>` tags (use `<div>`/`<span>`)
- [ ] `app-button` uses standard classes: `solid`/`light` + `primary`/`accent`/`warn`/`accept`
- [ ] No inline styles
- [ ] Text in Sentence case

#### Internationalization (i18n)

- [ ] User-visible text elements have `i18n` attribute
- [ ] Form field `label` attributes have `i18n-label`
- [ ] Form field `placeholder` attributes have `i18n-placeholder` (when user-facing text, not technical examples)

### SCSS Files (\*.scss)

#### Colors

- [ ] No hardcoded colors - must use `var(--syt-*)`

#### Spacing (must be multiples of 4px)

- [ ] gap: 2, 4, 8, 12, 16, 20, 24px
- [ ] padding: 4, 8, 12, 16px
- [ ] margin: 4, 8, 12, 16, 20px

#### Border Radius

- [ ] Only: 6px, 8px, 12px, 20px, 50%

#### Transitions

- [ ] Always `0.25s ease` with specific property name (NOT `all`)

#### Typography

- [ ] Font sizes: 9, 10, 11, 12, 14, 16, 18, 24px
- [ ] Font weights: 400, 500, 600, bold

#### Structure

- [ ] Uses `:host` pattern for component root

---

## Violation Report Format

For each violation, agents must report:

````markdown
### {filename}:{line}

**Rule**: {rule name}
**Issue**: {what's wrong}

**Current:**

```{lang}
{current code}
```
````

**Should be:**

```{lang}
{corrected code}
```

````

---

## Fix Violations

After reporting all violations:

1. Ask: "Found {N} violations. Fix them?"
2. If yes, fix each one sequentially with Edit tool
3. Confirm each fix: "Fixed {file}:{line} - {description}"

---

## Quick Reference: Most Common Violations

| Violation | Fix |
|-----------|-----|
| `providedIn: 'root'` on non-mapper service | Remove, provide at component level |
| Hardcoded color `#xxx` or `white` | Replace with `var(--syt-*)` |
| `gap: 7px` | Round to `8px` (multiple of 4) |
| Missing OnPush | Add `changeDetection: ChangeDetectionStrategy.OnPush` |
| `UPPER_CASE` constant | Convert to `camelCase` |
| `Date` type | Replace with `DateTime` from `@core/shared/domain` |
| `<p>` or `<h1>` tag | Replace with `<div>` or `<span>` |
| `transition: 0.3s` or `all 0.25s` | Change to `specific-property 0.25s ease` |
| `border-radius: 5px` | Change to `6px` or `8px` |
| Using Cubit (blac) | Migrate to StateManager pattern with signals |
| Missing test files | Create tests for usecases, state managers, repositories, mappers |
| `catch { }` or `catch (e) { }` generic | Catch specific exception with `instanceof`, re-throw others |
| Missing `i18n-label` on form field | Add `i18n-label` attribute |
| Missing `i18n-placeholder` on form field | Add `i18n-placeholder` attribute (if user-facing text) |
| Getter in component | Replace with `computed()` |
| `any` type | Define proper interface |
| Magic string `'value'` | Extract to named constant or enum |

---

## Output Summary

After compiling all agent results, present:

```markdown
## Review Summary

**Files Reviewed**: {count}
**Violations Found**: {count}

### HIGH
| # | File | Issue |
|---|------|-------|

### MEDIUM
| # | File | Issue |
|---|------|-------|

### LOW
| # | File | Issue |
|---|------|-------|
```

Then ask if the user wants to fix the violations.
````
