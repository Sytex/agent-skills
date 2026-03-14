---
name: pr
description: Create Pull Request
---

# Create Pull Request

You are creating a Pull Request from the current branch to `master`. Follow these steps:

> **IMPORTANT**: Always create PRs targeting `master` branch, NOT `development` or any other branch.

## Step 1: Get Issue Title from Linear

Extract the issue ID from the current branch name (format: `SYT-{issueId}-{slug}`) and fetch the issue details from Linear using the MCP tool `mcp__plugin_linear_linear__get_issue`.

The PR title MUST be: `{emoji} {issueTitle} (SYT-{issueId})`

## Step 2: Analyze Branch Changes

Get the full diff and commit history compared to master:

```bash
git log master..HEAD --oneline
git diff master...HEAD --stat
```

## Step 3: Check for Migrations

Check if the branch includes migration files:

```bash
git diff master...HEAD --name-only | grep -E "migrations/[0-9]+"
```

If migration files are found, the PR body MUST include a migration alert at the very top.

## Step 4: Generate PR Content

Based on the commits and changes, generate the PR body:

- **Migration alert** (only if migrations exist): Add at the top
- **What was the issue?**: Describe what problem this PR solves
- **What did you change?**: Summarize the key changes made

## Step 5: Create the PR

Use the `gh` CLI to create the PR.

**If migrations exist**, include the alert at the top:

```bash
gh pr create --base master --title "{emoji} {issueTitle} (SYT-{issueId})" --assignee @me --body "$(cat <<'EOF'
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
gh pr create --base master --title "{emoji} {issueTitle} (SYT-{issueId})" --assignee @me --body "$(cat <<'EOF'
## What was the issue?

{issue_description}

## What did you change?

{changes_description}
EOF
)"
```

## Step 6: Confirm Success

After creating the PR, display the PR URL to the user.
