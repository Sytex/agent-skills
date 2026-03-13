# Backend Agent Instructions

These instructions are inlined into the agent prompt by the orchestrator. The agent cannot invoke skills.

## Step 1 — Understand conventions

Read `CLAUDE.md` at the project root before starting.

## Step 2 — Investigate and implement

1. Research: read relevant code, understand the problem
2. Implement the fix/feature following project conventions
3. Commit after each meaningful change (see commit instructions below)

## Step 3 — Self-review

Review your own changes and fix violations directly — do not just report them.

### 4a. No-slop check

Get changed Python files:
```bash
git diff master --name-only --diff-filter=ACMR | grep -E '\.py$'
```

Read each file and fix these violations:

**No imports inside classes or functions** — move all imports to file level.

**No relative imports** (`from .module`, `from ..module`) — convert to absolute imports from Django app root.

**No logger unless explicitly requested** — remove `import logging`, `logger = logging.getLogger(...)`, and all `logger.*()` calls.

### 4b. Architecture & dependencies

- Django ORM calls (`Model.objects.*`, `.save()`, `.delete()`, `m2m_set.*`) exist ONLY in repository files
- Use cases contain business logic only, no ORM calls
- Views delegate to use cases, no business logic in views
- All dependencies injected via constructor with explicit typed params (no generic `dependencies` dict)
- DI wiring in `dependency_injection.py` using `DependencyContainer` with `@property`
- Use cases invoked via `__call__`, never `.execute()`
- Cross-domain imports go through the other domain's DI container
- One class per file when possible, with `__init__.py` barrel re-exports

### 4c. Code quality & style

- All parameters and variables have type hints (unless trivially inferred)
- Imports at file level, not inside classes/methods
- No relative imports — use absolute imports from Django app root
- Import grouping: stdlib, third-party, local
- Early returns and `continue` used to avoid nesting
- Boolean conditions extracted to descriptive variables
- No function calls passed as arguments — assign to variable first
- No "just in case" try/except — only catch specific expected exceptions
- No unused imports or dead code
- No `Optional` dependencies with `None` defaults for required collaborators
- Permission checks use `user.has_perm()`, not repository `filter_by_permission`

### 4d. Migrations

- `RunPython` operations must be in their own migration file — never mixed with schema operations (`CreateModel`, `AddField`, `AlterField`, `RemoveField`, etc.)
- If a feature needs both schema changes and data migration, create two separate migration files

Check any new migrations:
```bash
git diff master --name-only --diff-filter=A | grep -E 'migrations/[0-9]'
```
For each new migration file, verify it does not contain both `RunPython` and schema operations. If it does, split it into two files.

### 4e. Security & data integrity

- No hardcoded secrets, API keys, or credentials
- Input validation at system boundaries (views, serializers)
- No raw SQL queries (use ORM in repositories)
- Permission checks present on all endpoints

### 4f. Testing coverage

- New use cases, repositories, services, actions must have test files
- Tests use `SimpleTestCase` when no DB needed
- Tests use `create_autospec` for mocking interfaces
- Tests do NOT test private methods directly

### After review

Fix all violations found, then commit the fixes in a single commit (see commit instructions below).

## Step 4 — Run tests

Run unit tests for the code you changed:
```bash
cd app
uv run python manage.py test --settings=sytex.settings-tests --testrunner=sytex.tests.UnitTestRunner -v2 --failfast {test_modules}
```

Identify test modules from changed files:
- Changed `app/{domain}/usecases/foo.py` → test module: `{domain}.tests.test_foo`
- Changed `app/{domain}/repositories/bar.py` → test module: `{domain}.tests.test_bar`
- New test file `app/{domain}/tests/test_bar.py` → test module: `{domain}.tests.test_bar`
- If no relevant test file exists, skip

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

### Check for migrations

```bash
git diff master...HEAD --name-only | grep -E "migrations/[0-9]+"
```

### Create changelog fragment

Create a file at `changes/SYT-{issueId}.{type}.md` where type is `feature`, `improvement`, `fix`, or `doc`.

Format:
```markdown
{User-friendly title describing the change}

{2-4 bullet points in non-technical language}

- UI changes: {yes/no}
- Business logic changes: {yes/no}
- Owner: @{github_username}
- Linear link: [SYT-{issueId}](https://linear.app/sytex/issue/SYT-{issueId}/)
```

Get the GitHub username with: `gh api user --jq '.login'`

### Create draft PR

```bash
github_user=$(gh api user --jq '.login')
```

**If migrations exist**, include the alert at the top of the body:
```bash
gh pr create --base master \
  --title "{emoji} {issueTitle} (SYT-{issueId})" \
  --assignee "$github_user" \
  --draft \
  --body "$(cat <<'EOF'
> [!CAUTION]
> This PR includes database migrations

## What was the issue?

{issue_description}

## What did you change?

{changes_description}
EOF
)"
```

**If NO migrations**, omit the alert:
```bash
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
