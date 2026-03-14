---
name: test
description: Run Angular unit tests using Karma with ChromeHeadless. Use when asked to run tests, verify tests pass, or test specific files.
allowed-tools: Bash(ng test:*), Bash(NODE_OPTIONS:*)
argument-hint: [file paths...]
---

# Run Tests

Run Angular unit tests with ChromeHeadless browser.

## Command

```bash
NODE_OPTIONS=--max_old_space_size=8192 ng test --browsers=Headless --no-watch
```

## Input Modes

Determine the test scope based on `<argument>`:

| Input             | Action                                          |
| ----------------- | ----------------------------------------------- |
| No argument       | Run all tests                                   |
| File path(s)      | Run only the specified spec files with --include |
| `branch`/`changes`| Run tests for files changed vs master            |

## Step 1: Determine Files to Test

**For specific files:**

Use `--include` flag for each file:

```bash
NODE_OPTIONS=--max_old_space_size=8192 ng test --browsers=Headless --no-watch --include='<file1>' --include='<file2>'
```

**For branch changes:**

First find changed spec files:

```bash
git diff master --name-only --diff-filter=ACMR | grep '\.spec\.ts$'
```

Then run with `--include` for each spec file found.

**For all tests:**

```bash
NODE_OPTIONS=--max_old_space_size=8192 ng test --browsers=Headless --no-watch
```

## Step 2: Run and Report

1. Execute the test command
2. Report results: total tests, passed, failed
3. If failures exist, show the failing test names and error messages
