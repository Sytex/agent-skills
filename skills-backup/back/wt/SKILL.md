---
name: wt
description: Manage worktrees for parallel development (create, bootstrap, run, clean, status)
---

# Worktrees

You are helping the user manage git worktrees for parallel local development of the `sytex` backend.

## Directory Layout

```
back/
  master/                          # Main worktree, runs full stack
  feature/SYT-XXXX-slug/          # Secondary worktrees, run sytex + proxy only
  bugfix/SYT-YYYY-slug/
```

- `master/` has `.git/` (directory) and runs all services: mysql, rabbit, redis, elastic, alfred, sytex, proxy
- Secondary worktrees have `.git` (file) and run only `sytex` + `proxy`, sharing master's services via `host.docker.internal`
- Proxy ports are deterministic per worktree name (no collisions)

## Available Commands

All commands are run with `just` from within a worktree directory.

### Create a new worktree

```bash
just wt-new <branch-name> [base-branch]
```

- Creates `back/<branch-name>/` as a new worktree
- If `<branch-name>` already exists locally, checks it out; otherwise creates from `base-branch` (default: `master`)
- Ensures master shared services are running
- Bootstraps the worktree (compose overrides, .venv seed, certs)
- Starts `sytex` + `proxy` in the new worktree
- Prints the proxy URL

Example:
```bash
just wt-new feature/SYT-1234-add-reports
```

### Bootstrap a worktree

```bash
just wt-bootstrap [master-path] [wait-for-venv] [run-uv-sync] [show-proxy-url]
```

- Seeds `.venv` from master in background (if not already present)
- Symlinks SSL certs from master
- Generates `compose.worktree.override.yaml` with:
  - Deterministic proxy ports
  - `sytex` ports overridden to `[]`
  - Shared services scaled to 0
  - `sytex` environment pointing to `host.docker.internal`
- Configures `.env` with `COMPOSE_FILE` chain
- Copies test DB sqlite if present

Defaults: auto-detects master path, waits for venv, runs uv sync, shows proxy URL.

Quick bootstrap (no wait, no uv sync):
```bash
just wt-bootstrap "../master" "0" "0" "0"
```

### Start services

```bash
just run
```

- **From master**: runs `docker compose --profile master up -d` (full stack)
- **From worktree**: runs only `sytex` + `proxy` with `--no-deps`, using compose override chain

### Check connectivity

```bash
just wt-check-connectivity
```

- Verifies the worktree's `sytex` container can reach master's MySQL (3306) and RabbitMQ (5672) via `host.docker.internal`
- Retries up to 15 times with 1s delay

### Clean a worktree

```bash
just wt-clean [target]
```

- `target` defaults to current directory (`.`)
- Can specify a worktree name: `just wt-clean feature/SYT-1234-add-reports`
- Stops Docker services for the worktree
- Removes containers, networks, volumes, and local images
- Kills background `.venv` seed if running
- Removes the git worktree and deletes the local branch
- Refuses to clean master

### Other standard commands (work in any worktree)

All these prepend `--profile master` automatically:

```bash
just stop [services]          # Stop services
just restart [services]       # Restart services
just bash                     # Shell into sytex container
just logs [service]           # Follow logs (default: sytex)
just shell_plus               # Django shell_plus
just manage <command>         # Run manage.py command
just test <target>            # Run integration tests
just unit_test <target>       # Run unit tests
just makemigrations [app]     # Create migrations
just migrate [app]            # Run migrations
just celery [queue]           # Start celery worker
just local_debug              # Run Django dev server with ipdb
```

## How to Operate

### When the user asks to create/start a new worktree:

1. Confirm the branch name
2. Ensure you're in the `master/` directory (or any existing worktree)
3. Run `just wt-new <branch>`
4. Report the proxy URL

### When the user asks to check worktree status:

```bash
# List all worktrees
git worktree list

# List running containers across all worktrees
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(master|sytex_)"
```

### When the user asks to remove a worktree:

1. Run `just wt-clean <target>` from master or any other worktree
2. Confirm cleanup was successful

### When the user reports connectivity issues in a worktree:

1. Verify master services are running: `docker compose --profile master ps` (from master)
2. Run `just wt-check-connectivity` from the worktree
3. If failing, check that master's mysql and rabbit ports are exposed to the host

### When the user asks which port a worktree uses:

```bash
bin/wt-ports.sh <worktree-name>
```

The worktree name is `basename` of the directory (e.g., `SYT-1234-add-reports`, not the full branch path).

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| `docker-compose.yml` | Every worktree | Base compose (shared services have `profiles: [master]`) |
| `compose.override.yaml` | `master/` only | Personal overrides (gitignored) |
| `compose.worktree.override.yaml` | Secondary worktrees | Auto-generated by `wt-bootstrap` (gitignored) |
| `.env` | Secondary worktrees | Contains `COMPOSE_FILE` chain (gitignored) |
| `bin/wt-ports.sh` | `master/` | Calculates deterministic ports from worktree name |
| `.venv.seed.pid` / `.venv.seed.log` | Secondary worktrees | Background venv copy tracking (gitignored) |
