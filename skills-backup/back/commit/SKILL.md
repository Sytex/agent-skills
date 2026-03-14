---
name: commit
description: Create Commit
---

# Create Commit

You are creating a commit for the current branch changes. Follow these steps:

## Step 1: Verify Branch

Run `git branch --show-current` to check the current branch.

**IMPORTANT**: If the current branch is `master` or `main`, STOP and inform the user:
- "Cannot commit directly to master/main branch. Please create a feature branch first."
- Do NOT proceed with the commit.

## Step 2: Analyze Changes

Run these commands to understand what changed:

```bash
git status
git diff --staged
git diff
```

If there are no staged changes, stage all changes automatically.

## Step 3: Get Commit Message

If the user provided a commit message, use it. Otherwise, analyze the changes and propose a commit message following this format:

- Start with an emoji indicating the type of change:
  - New feature
  - Bug fix
  - Refactoring
  - Documentation
  - Testing
  - Security

- Keep the message concise (1-2 sentences)
- Focus on WHAT changed and WHY

Proceed with the commit using this message.

## Step 4: Stage and Commit

1. Stage the files (if not already staged)
2. Run the commit command

## Step 5: Handle Pre-commit Hook

The project has a pre-commit hook that may auto-format code. If the commit fails due to formatting:

1. **Do NOT use `--amend`**
2. **Do NOT use any workarounds**
3. Simply run:
   ```bash
   git add -A
   git commit -m "same message"
   ```
4. If it fails again, repeat the process (the hook should pass on the second attempt after auto-formatting)

## Step 6: Verify Success

Run `git status` to confirm the commit was successful.

## Commit Message Format

Use a HEREDOC for the commit message:

```bash
git commit -m "$(cat <<'EOF'
{emoji} {message}
EOF
)"
```

## Examples

Good commit messages:
- Add activity logging system for tracking entity changes
- Fix null pointer exception in user authentication
- Simplify database query logic in reports module
