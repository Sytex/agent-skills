# Frontend Agent Instructions

These instructions are inlined into the agent prompt by the orchestrator. The agent cannot invoke skills.

## Step 1 — Understand conventions

Read these files from the worktree before starting:
- `CLAUDE.md` at project root
- `agents/standards/standards.md`

## Step 2 — Investigate and implement

1. Research: read relevant code, understand the problem
2. Implement the fix/feature following project conventions
3. Commit after each meaningful change (see commit instructions below)

## Step 3 — Self-review

Review your own changes against these rules. Fix violations directly — do not just report them.

### Get the diff

```bash
git diff master --name-only --diff-filter=ACMR | grep -E '\.(ts|html|scss)$'
```

Read each changed file and check against the checklist below.

### TypeScript rules

**Architecture:**
- No `providedIn: 'root'` in `@Injectable()` (exception: stateless mappers)
- Correct layer placement (domain/application/infrastructure/presentation)
- Components do NOT call use cases or inject repositories directly — must use a State Manager
- Result pattern: `Result<Error, Data>` or `Observable<Result<...>>`

**Naming:**
- File name: `{name}.{type}.ts` (usecase, repository, state-manager, component, etc.)
- Classes: PascalCase
- Private members: `_camelCase` prefix
- Constants: camelCase (NOT UPPER_CASE)
- API interfaces: `Api` prefix (`ApiUser`, `ApiResponse`)

**Structure:**
- Method order: public props → private props → constructor → public methods → private methods
- Interfaces BELOW class definition
- Complex types extracted to named interfaces

**Components:**
- `ChangeDetectionStrategy.OnPush` present
- Using `signal()` for reactive state (not `markForCheck()`)
- `computed()` instead of getters
- `effect()` instead of setters/ngOnChanges
- All dependencies in `providers` array
- State manager calls are fire-and-forget (no `await`, no boolean check)
- Loading/error signals derived from state manager `computed()` (not local `signal()`)
- No direct HTTP calls or use case injections

**State Managers:**
- Uses StateManager pattern (NOT Cubit from blac)
- State interface and initial state exported
- `_state` NOT exposed directly (use `computed()`)
- Has `reset()` method
- All async methods return `Promise<void>` (NEVER `Promise<boolean>`)

**Use Cases:**
- Single `execute()` method
- Returns `Result<CustomError, Entity>`
- Uses `CommonUseCaseError` type alias
- Injects `CommonUseCaseErrorMapper`

**Entities:**
- Extends `Entity` base class
- Has `copyWith()` method
- Uses `DateTime` for dates (not `string` or `Date`)

**Code style:**
- Curly brackets on ALL if/for/while (even single-line)
- No magic strings or numbers (use named constants or enums)
- No `any` type usage (define proper interfaces)
- No unused imports
- Barrel files (index.ts) updated for new files
- No inline dynamic imports — use top-level static imports
- No "just in case" try/catch blocks
- No function calls passed as arguments — assign to variable first

### HTML rules

- No native HTML form elements (`<input>`, `<select>`, `<textarea>`, `<button>`) — use shared components (`<app-input>`, `<app-select>`, `<app-textarea>`, `<app-button>`)
- No `<p>`, `<h1>`-`<h6>` tags (use `<div>`/`<span>`)
- `app-button` uses standard classes: `solid`/`light` + `primary`/`accent`/`warn`/`accept`
- No inline styles
- Text in sentence case (NOT Title Case)
- Column headers are user-friendly, not abbreviated
- User-visible text has `i18n` attribute
- Form field `label` has `i18n-label`
- Form field `placeholder` has `i18n-placeholder` (when user-facing text)

### SCSS rules

- No hardcoded colors — use `var(--syt-*)`
- Spacing: multiples of 4px (gap: 2,4,8,12,16,20,24px; padding: 4,8,12,16px; margin: 4,8,12,16,20px)
- Border radius: only 6px, 8px, 12px, 20px, 50%
- Transitions: `0.25s ease` with specific property (NOT `all`)
- Font sizes: 9,10,11,12,14,16,18,24px
- Font weights: 400, 500, 600, bold
- Uses `:host` pattern for component root

### Testing coverage

- New usecases, state managers, repositories, mappers must have test files
- Check if any are missing and create them

### After review

Fix all violations found, then commit the fixes in a single commit (see commit instructions below).

## Step 4 — Run tests

Run tests for changed files:
```bash
NODE_OPTIONS=--max_old_space_size=8192 npx ng test --browsers=Headless --no-watch --include='{spec_file}'
```

Identify spec files from changed files:
- Changed `src/app/foo/bar.component.ts` → spec: `src/app/foo/bar.component.spec.ts`
- Changed `src/app/foo/bar.usecase.ts` → spec: `src/app/foo/bar.usecase.spec.ts`
- If the spec file doesn't exist, skip

If tests fail, fix the issues and re-run. Only proceed to commit when tests pass.

## Step 5 — Commit

Before each commit:
1. Run `git branch --show-current` — if on `master` or `main`, STOP
2. Stage changes: `git add -A`
3. Commit with HEREDOC format:
   ```bash
   git commit -m "$(cat <<'EOF'
   {emoji} {concise description}
   EOF
   )"
   ```
4. If pre-commit hook fails (formatting), just re-stage and commit again:
   ```bash
   git add -A
   git commit -m "$(cat <<'EOF'
   {emoji} {same message}
   EOF
   )"
   ```

Emoji guide: new feature, bug fix, refactoring, tests, docs, security.

**After self-review, squash review fixes into a single commit** rather than one commit per fix.

## Step 6 — Push

```bash
git push -u origin {branch_name}
```

## Step 7 — Create PR

### Get issue title from Linear

Extract the issue ID from the branch name (format: `SYT-{issueId}-{slug}`).
Fetch the issue details from Linear using `mcp__claude_ai_Linear__get_issue`.

PR title: `{emoji} {issueTitle} (SYT-{issueId})`

### Analyze changes

```bash
git log master..HEAD --oneline
git diff master...HEAD --stat
```

### Create draft PR

```bash
github_user=$(gh api user --jq '.login')
gh pr create --base master \
  --title "{emoji} {issueTitle} (SYT-{issueId})" \
  --assignee "$github_user" \
  --draft \
  --body "$(cat <<'EOF'
## What was the issue?

{issue_description}

## What did you change?

{changes_description}
EOF
)"
```

Do NOT run `gh pr ready` — the user decides when the PR is ready for review.

## Step 8 — Start dev server

Start `ng serve` in the background so the user can test immediately:

```bash
nohup just serve > /tmp/ng-serve-$(basename "$PWD").log 2>&1 &
```

Report the URL to the user: `https://{DEV_DOMAIN}:{port}/o/1/` (get the port from `bin/wt-ports.sh`).
