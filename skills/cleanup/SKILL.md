---
name: cleanup
description: Analyze and clean up disk space on the Kadmos instance. Use when user asks about disk usage, cleanup, freeing space, or when the daily report shows disk warnings.
allowed-tools:
  - Bash(~/.claude/skills/cleanup/*:*)
---

# Cleanup Skill

Manages disk space on the Kadmos instance. Can run interactively (with report) or automated (quiet mode for cron).

## Commands

### Status Report
```bash
cleanup status
```
Shows disk usage breakdown by category with actionable recommendations.

### Automated Cleanup (cron-safe)
```bash
cleanup auto
```
Runs all safe cleanups non-interactively:
- Worktrees older than 5 days (stops their Docker containers first)
- Claude telemetry, debug logs, and sessions older than 30 days
- npm/apt cache
- Old system logs (keeps 50MB)
- /tmp files older than 1 day
- Stopped Docker containers
- Dangling Docker images/volumes
- Snap saved snapshots

### Selective Cleanup
```bash
cleanup worktrees [--max-age DAYS]   # Default: 5 days
cleanup docker                        # Stopped containers + dangling images
cleanup cache                         # npm, apt, Claude telemetry/debug/sessions
cleanup logs                          # Journal vacuum + rotated logs
cleanup tmp                           # /tmp files older than 1 day
```

### Dry Run
```bash
cleanup auto --dry-run
cleanup worktrees --dry-run
```

## Safety Rules

1. **NEVER** remove the `master` worktree or its Docker containers
2. **NEVER** remove Docker images used by running containers (except worktree containers being cleaned)
3. **NEVER** touch `/home/ubuntu/projects/back/master` or `/home/ubuntu/projects/front/master`
4. Worktree cleanup stops related Docker containers before removing the worktree
5. The `auto` command only removes worktrees older than 5 days by default
6. Always show a summary of what was cleaned and space recovered

## Cron Integration

The cleanup runs daily at 03:00 ART (06:00 UTC) via crontab:
```
0 6 * * * ~/.claude/skills/cleanup/cleanup auto >> /tmp/cleanup.log 2>&1
```

The older `syt-gc` cron (merged-worktree-only) still runs every 6h as a safety net.
