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

## Step 3: Generate PR Content

Based on the commits and changes, generate the PR body:

- **What was the issue?**: Describe what problem this PR solves
- **What did you change?**: Summarize the key changes made

## Step 4: Create the PR

Use the `gh` CLI to create the PR:

```bash
gh pr create --base master --title "{emoji} {issueTitle} (SYT-{issueId})" --assignee @me --body "$(cat <<'EOF'
## What was the issue?

{issue_description}

## What did you change?

{changes_description}
EOF
)"
```

## Step 5: Confirm Success

After creating the PR, display the PR URL to the user.
