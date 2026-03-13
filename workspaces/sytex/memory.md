# Sytex Stack

This is the root directory containing all Sytex platform projects.

## Projects

| Project  | Main worktree    | Repo           | Stack                  |
|----------|-----------------|----------------|------------------------|
| backend  | `./back/master`  | `Sytex/sytex`  | Django, Python, uv     |
| frontend | `./front/master` | `Sytex/front`  | Angular, TypeScript    |

## Workflow

Use the `/issue` skill to work on issues end-to-end. It handles:
- Linear issue creation/lookup and assignment
- Sentry linking
- Branch and worktree creation across projects (via `just wt-new`)
- Implementation, testing, review, and PR creation

## Conventions

- **Branch naming**: `SYT-{id}-{slug}` — same name across all repos for the same issue
- **Base branch**: `master` in all repos. Always branch from `origin/master`
- **Worktrees**: Created via `just wt-new` as siblings of `master/` (e.g., `./back/SYT-123-slug/`). Each worktree is self-contained with its own environment (Docker for backend, symlinked node_modules for frontend)
- **Main worktree** (`master/`): Runs the full stack. Always stays on `master`. Use `just run` (backend) or `just serve` (frontend) to start
- **Linear team**: `SYT`
- **Each project has its own skills** — always use the project-specific skills for PRs, reviews, commits, etc.
- **Issue lifecycle**: An issue is considered closed when its PR is merged to `master`. Worktrees are cleaned up via `/worktree-cleanup` or `just wt-clean`
