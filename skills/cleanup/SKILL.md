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
Shows disk usage by category, then every worktree with its size and age. Stale ones
(older than `--max-age`) are flagged `STALE`, worktrees protected by the safety guard are
flagged `held: <reason>`, and the total reclaimable space is printed as a warning.

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
- Docker build cache older than 7 days
- Snap saved snapshots

### Selective Cleanup
```bash
cleanup worktrees [--max-age DAYS]   # Default: 5 days
cleanup docker                        # Stopped containers + dangling images + build cache
cleanup cache                         # npm, apt, Claude telemetry/debug/sessions
cleanup logs                          # Journal vacuum + rotated logs
cleanup tmp                           # /tmp files older than 1 day
```

### Dry Run
```bash
cleanup auto --dry-run
cleanup worktrees --dry-run
```

## Worktree Discovery

Worktrees are **not** found by globbing well-known paths — that silently missed most of them
(SYT-11835). Discovery is derived from git:

1. **Repositories** — `find $PROJECTS_DIR -maxdepth 3 -name .git`, each mapped to its main
   worktree via `git rev-parse --git-common-dir`. Nothing is hardcoded, so `back` being a
   symlink, `front` no longer existing, and new repos appearing are all handled.
2. **Worktrees** — `git worktree list --porcelain` per repo. This is authoritative: it catches
   every path and name, including worktrees nested inside the master checkout
   (`master/SYT-…`, `master/.claude/worktrees/agent-…`) and ones that are not named `SYT-*`.
3. **Orphans** — directories git no longer knows about, swept from *worktree containers only*:
   the parent of a main worktree named `master`/`main`, any `.worktrees`/`worktrees` directory,
   and the main worktree itself. A directory qualifies as an orphan when it has a `.git` file
   whose gitdir target is gone, or no git metadata at all and no `.git` in any ancestor. A
   `.git` **directory** means a repository root and is never touched.

Age comes from `git log -1` inside the worktree, **falling back to the directory mtime** when
that fails. Previously a broken gitdir link made a worktree immortal: `git log` failed, the age
was unknown, and the loop skipped it — so the most abandoned directories were exactly the ones
never cleaned.

## Safety Rules

1. **NEVER** remove a worktree with uncommitted changes (`git status --porcelain` non-empty) or
   with commits not reachable from any remote-tracking ref — regardless of age. Held worktrees
   are named in the summary.
2. **NEVER** remove a repository's main worktree, or a directory that still contains a live
   worktree.
3. **NEVER** sweep `$PROJECTS_DIR` itself, `/home/ubuntu`, `/home`, `/tmp` or `/var` — they hold
   far more than worktrees.
4. **NEVER** remove Docker images used by running containers (except worktree containers being
   cleaned)
5. Worktree cleanup stops related Docker containers first, matching Compose's naming: an exact
   or `<worktree>-` / `<worktree>_` prefix match, case-insensitive. A bare substring match would
   let a worktree named `sytex` take down `master-sytex-1`.
6. The `auto` command only removes worktrees older than 5 days by default
7. Always show a summary of what was cleaned and space recovered

## Resilience

A single failing worktree (e.g. root-owned Docker bind-mount stubs like
`back/logs`, `back/cli/target`, `back/sytex.io.{crt,key}`) must never abort the
full `auto` run. Removal escalates through `git worktree remove --force`,
`rm -rf`, and `sudo -n rm -rf`. Worktrees that still cannot be removed are
recorded and listed in the final summary so they can be handled manually,
while the remaining cleanup stages (Docker, cache, logs, tmp) still run.

The summary also compares the stale space the run *saw* against what it actually *freed*, and
warns when more than 512 MB was left behind. A run that reports "Recovered: 44 KB" while 8 GB of
stale worktrees sit on disk now says so out loud instead of looking healthy.

## Cron Integration

The cleanup runs daily at 03:00 ART (06:00 UTC) via crontab:
```
0 6 * * * ~/.claude/skills/cleanup/cleanup auto >> /tmp/cleanup.log 2>&1
```

The older `syt-gc` cron (merged-worktree-only) still runs every 6h as a safety net.
