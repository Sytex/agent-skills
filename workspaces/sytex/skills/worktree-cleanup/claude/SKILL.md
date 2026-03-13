---
name: worktree-cleanup
description: List and clean up git worktrees. Use when user asks about worktrees, cleaning worktrees, or removing stale worktrees.
allowed-tools: Bash(just *), Bash(git *), Bash(gh pr *), Bash(pkill *)
---

# Worktree Cleanup

List git worktrees, detect merged issues, and clean up using `just wt-clean`.

## Instructions

For each Sytex project (backend: `./back/master` → `Sytex/sytex`, frontend: `./front/master` → `Sytex/front`):

### 1. List worktrees

```bash
cd {main_worktree}
just wt-list
```

### 2. Detect merged worktrees

```bash
cd {main_worktree}
git fetch origin master

git worktree list --porcelain | grep "^worktree " | while read -r line; do
  wt_path="${line#worktree }"
  branch=$(basename "$wt_path")
  [ "$branch" = "master" ] && continue
  merged=$(gh pr list --repo {repo} --head "$branch" --state merged --json number --jq 'length')
  if [ "$merged" -gt 0 ]; then
    echo "MERGED: $branch"
  else
    echo "ACTIVE: $branch"
  fi
done
```

### 3. Present options

Use `AskUserQuestion` with `multiSelect: true`:
- Pre-label merged worktrees as "(merged)" — recommend removing these
- Show active worktrees too, in case the user wants to remove them
- Let the user select which ones to remove

### 4. Remove selected worktrees

**Frontend**: kill any running `ng serve` for the worktree before cleaning:
```bash
# Find and kill ng serve on the worktree's port
port=$({main_worktree}/bin/wt-ports.sh {branch-name})
lsof -ti :${port} | xargs kill 2>/dev/null || true
```

Then clean each selected worktree:
```bash
cd {main_worktree}
just wt-clean {branch-name}
```

After all removals: `git worktree prune`

### 5. Summary

Show what was removed and the current state (`just wt-list`).
