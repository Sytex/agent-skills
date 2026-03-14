---
name: pr-review-fix
description: Reviews PR comments and applies requested changes. Use when user provides a GitHub PR URL and wants to address review feedback.
---

# PR Review Fix

You are reviewing and fixing a Pull Request based on review comments.

## Step 1: Get PR Information

If the user provides a PR URL (e.g., `https://github.com/Sytex/sytex/pull/123`), extract the PR number and fetch:

```bash
# Get PR details and comments
gh pr view {PR_NUMBER} --repo Sytex/sytex --json title,body,comments,reviews,state,headRefName

# Get review comments with file paths
gh api repos/Sytex/sytex/pulls/{PR_NUMBER}/comments
```

## Step 2: Checkout the PR Branch

Ensure you're on the correct branch:

```bash
git fetch origin
git checkout {branch_name}
```

## Step 3: Analyze Review Comments

For each review comment, identify:
- **File path**: Where the change is needed
- **Requested change**: What needs to be done
- **Type of change**: Refactor, bug fix, improvement, etc.

Summarize all comments in a table for the user:

| # | File | Comment | Status |
|---|------|---------|--------|
| 1 | path/to/file.py | Description of change | Pending |

## Step 4: Apply Changes

For each comment:

1. **Read the file** to understand current implementation
2. **Check documentation** in `/app/<module>/docs/` if relevant
3. **Apply the fix** following project patterns
4. **Update tests** if the change affects behavior

### Common Review Patterns

#### Dependency Injection
```python
# BAD: Direct import usage
from django.conf import settings
class Service:
    def __init__(self):
        self.key = settings.SOME_KEY

# GOOD: Inject dependencies
class Service:
    def __init__(self, some_key: str) -> None:
        self._key = some_key
```

#### Folder Structure
- Use `entities/` for types, enums, and domain objects (not `enums/`, `types/`)
- Use `exceptions.py` for module-specific errors

#### Error Types
```python
# BAD: Generic ValidationError with string message
raise ValidationError("Name already exists")

# GOOD: Specific error type inheriting from SytexBusinessError
class NameAlreadyExistsError(SytexBusinessError):
    def __init__(self) -> None:
        super().__init__({"name": ["Name already exists."]})
```

#### Type Hints
```python
# BAD: Using Callable for modules
def __init__(self, requests_module: Callable) -> None:

# GOOD: Using ModuleType
from types import ModuleType
def __init__(self, requests_module: ModuleType) -> None:
```

#### Soft Delete vs Hard Delete
- For sensitive data (credentials, secrets): Use **hard delete**
- Update migration if changing from soft delete

## Step 5: Run Tests

Always run tests for modified functionality:

```bash
just unit_test {module}.tests
```

## Step 6: Mark Comments as Resolved

After applying all changes, resolve the review threads:

```bash
# Get thread IDs
gh api graphql -f query='
query {
  repository(owner: "Sytex", name: "sytex") {
    pullRequest(number: {PR_NUMBER}) {
      reviewThreads(first: 50) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes { body path }
          }
        }
      }
    }
  }
}'

# Resolve each thread
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "{THREAD_ID}"}) {
    thread { isResolved }
  }
}'
```

## Step 7: Commit Changes

Use the `/commit` skill to create a commit with a descriptive message summarizing all fixes.

## Step 8: Update PR Description

If significant changes were made, update the PR description:

```bash
gh pr edit {PR_NUMBER} --body "updated description"
```

## Output

After completing all fixes, provide a summary:

| # | File | Comment | Status |
|---|------|---------|--------|
| 1 | path/to/file.py | Description | ✅ Fixed |
| 2 | path/to/other.py | Description | ✅ Fixed |

**Tests:** X tests passing ✅
**Commits:** List of commits created
