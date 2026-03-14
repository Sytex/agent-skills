---
name: review
description: Code review and standards enforcement for Sytex Django backend. Use when asked to review code in a folder, file, branch changes, or pull request. Validates code against project standards and offers to fix violations.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*), Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh api:*), Bash(find:*), Edit, Task, TaskCreate, TaskUpdate, TaskList, TaskGet, TeamCreate, TeamDelete, SendMessage
argument-hint: [path | branch | pr <number>]
---

# Code Review and Standards Enforcement

You are performing a code review to ensure compliance with Sytex backend standards.

## Standards Reference

Read `CLAUDE.md` at the project root before reviewing. It contains the authoritative coding standards.

## Input Modes

Determine the review mode based on `$ARGUMENTS`:

| Input                           | Mode          | Action                                    |
| ------------------------------- | ------------- | ----------------------------------------- |
| File/folder path                | Path Review   | Review all .py files in path              |
| `branch` or `changes`           | Branch Review | Review files changed vs master            |
| `pr <number>` or `PR #<number>` | PR Review     | Review files changed in the PR            |

---

## Execution Strategy: Always Parallel

Split the review into 4 areas and run them **all in parallel**:

| Area | Scope |
|------|-------|
| Architecture & dependencies | ORM only in repositories, DI patterns, use case / repository separation, no generic `dependencies` param |
| Code quality & style | Type hints, naming, imports, early returns, no "just in case" try/except, no function calls as arguments |
| Security & data integrity | Input validation, permission checks, no raw SQL, no hardcoded secrets, OWASP top 10 |
| Testing coverage | Missing tests for new use cases, repositories, services, actions |

### If Agent Teams is available

1. Create a team named `review-{context}` (e.g., `review-pr-2899`)
2. Create 4 tasks (one per area)
3. Spawn 4 agents simultaneously (`arch-reviewer`, `style-reviewer`, `security-reviewer`, `test-reviewer`) with `run_in_background: true` and `team_name`
4. Each agent reads `CLAUDE.md` first, gets the diff, checks its area, reports violations, marks task completed
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
find $ARGUMENTS -type f -name "*.py" | head -100
```

**For Branch:**

```bash
git diff master --name-only --diff-filter=ACMR | grep -E '\.py$'
```

**For PR:**

```bash
gh pr diff <number> --name-only | grep -E '\.py$'
```

---

## Review Checklist by Area

### Architecture & Dependencies

- [ ] Django ORM calls (`Model.objects.*`, `.save()`, `.delete()`, `m2m_set.*`) exist ONLY in repository files
- [ ] Use cases contain business logic only, no ORM calls
- [ ] Views delegate to use cases, no business logic in views
- [ ] All dependencies injected via constructor with explicit typed params (no generic `dependencies` dict)
- [ ] DI wiring lives in `dependency_injection.py` using `DependencyContainer` with `@property`
- [ ] `di = DependencyContainer()` at bottom of `dependency_injection.py`
- [ ] Use cases invoked via `__call__`, never `.execute()`
- [ ] Cross-domain imports go through the other domain's DI container
- [ ] One class per file when possible, with `__init__.py` barrel re-exports
- [ ] Repositories exist for all data access needs (if missing, flag it)

### Code Quality & Style (includes no-slop rules)

- [ ] All parameters and variables have type hints (unless trivially inferred)
- [ ] Imports at file level, not inside classes/methods (except circular import workarounds)
- [ ] No relative imports (`from .module` or `from ..module`) — use absolute imports from Django app root
- [ ] Import grouping: stdlib, third-party, local
- [ ] No logger unless explicitly requested (`import logging`, `logger = logging.getLogger(...)`, `logger.*()`)
- [ ] Early returns and `continue` used to avoid nesting
- [ ] Boolean conditions extracted to descriptive variables
- [ ] No function calls passed as arguments — assign to variable first
- [ ] No "just in case" try/except — only catch specific expected exceptions
- [ ] No unused imports or dead code
- [ ] No `Optional` dependencies with `None` defaults for required collaborators
- [ ] Permission checks use `user.has_perm()`, not repository `filter_by_permission`
- [ ] Meaningful names for classes, methods, and variables
- [ ] Single responsibility: functions are small and focused

### Security & Data Integrity

- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Input validation at system boundaries (views, serializers)
- [ ] No raw SQL queries (use ORM)
- [ ] No command injection vectors (untrusted input in shell commands)
- [ ] Permission checks present on all endpoints
- [ ] Serializer validation for user input
- [ ] No mass assignment vulnerabilities (explicit field lists in serializers)
- [ ] File upload validation (type, size) where applicable
- [ ] Sensitive data not exposed in API responses

### Migrations

- [ ] `RunPython` operations are in their own migration file, never mixed with schema operations (`CreateModel`, `AddField`, `AlterField`, `RemoveField`, etc.)

### Testing Coverage

- [ ] New use cases have corresponding test files
- [ ] New repositories have corresponding test files
- [ ] New actions have corresponding test files
- [ ] New services have corresponding test files
- [ ] Tests use `SimpleTestCase` when no DB needed, `TestCase` when DB required
- [ ] Tests use `create_autospec` for mocking interfaces
- [ ] Tests do NOT test private methods directly
- [ ] Edge cases covered (empty inputs, None values, invalid data)
- [ ] Tests follow existing patterns in the module's `tests/` directory

---

## Violation Report Format

For each violation, agents must report:

````markdown
### {filename}:{line}

**Rule**: {rule name}
**Severity**: HIGH | MEDIUM | LOW
**Issue**: {what's wrong}

**Current:**

```python
{current code}
```
````

**Should be:**

```python
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
| ORM call outside repository | Move to repository, inject repository in caller |
| `def execute(self, ...)` on use case | Rename to `__call__` |
| Generic `dependencies` param | Inject specific typed dependencies |
| Missing type hints | Add type annotations |
| Function call as argument | Assign to variable first |
| `try: ... except Exception:` | Catch only specific expected exceptions |
| `Optional` dependency with `None` default | Make required (no default) |
| Imports inside function/method | Move to file level |
| Relative imports (`from .module`) | Convert to absolute imports from app root |
| `logger` / `logging` usage | Remove unless explicitly requested |
| Nested conditionals | Use early returns / continue |
| Missing tests for new code | Create test file following module patterns |
| Hardcoded magic strings/numbers | Extract to constants |
| `RunPython` mixed with schema ops | Split into two migration files |

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
