---
name: impleload
description: Use this skill when an agent must operate Impleload from the CLI, automate implementation workload tasks, create/update/list/delete activities, create/update/list/delete worklogs, authenticate with Google CLI auth, or act through IMPLELOAD_AGENT_TOKEN with an actor email or Discord user. Use for business operations around implementer capacity, client implementation activities, scope consumption, weekly work logs, and audited agent-driven changes.
---

# Impleload CLI

## Purpose

Use the Impleload CLI to operate implementation workload data from a terminal, script, or agent. It is the preferred non-browser interface for activity and worklog operations because it preserves backend validation, authentication, and audit attribution.

## Decide Whether To Use The CLI

Use the CLI when the task asks to:

- List, inspect, create, update, or delete implementation activities.
- Record, inspect, update, or delete weekly worklogs for an activity.
- Automate Impleload operations from an agent, bot, scheduled job, or script.
- Perform an audited action on behalf of a user identified by email or Discord user id.
- Check the authenticated CLI user with `auth whoami`.

## Locate The Binary

Prefer an installed `impleload` on `PATH`. To install the released CLI:

```bash
mkdir -p "$HOME/.local/bin"
curl -fsSL https://impleload.sytex.io/static/cli/install.sh | IMPLELOAD_CLI_INSTALL_DIR="$HOME/.local/bin" bash
```

The installer detects the user's OS and CPU architecture and downloads the matching release binary. If `impleload` is still not found after installation, use `$HOME/.local/bin/impleload` (or `$HOME/.local/bin/impleload.exe` on Windows/Git Bash) or add `$HOME/.local/bin` to `PATH`.

Use `impleload --help` and subcommand help when in doubt. The CLI is intentionally small and self-documenting.

## Authentication

If this skill was installed with the Agent Skills installer, configuration may exist in `.env` alongside `SKILL.md` in the installed skill directory. Source it before running CLI commands when available:

```bash
set -a
source .env
set +a
```

For an OAuth session, use Google CLI auth:

```bash
impleload auth login
impleload auth whoami
```

Important details:

- `auth login` uses Google OAuth Desktop + PKCE and stores local session files.
- `auth whoami` verifies the saved token against `/api/me`.
- Use `--base-url` or `IMPLELOAD_BASE_URL` when targeting a non-default backend.
- Use `auth login --no-open` only for headless environments where the user can open the printed URL manually.
- An agent can use OAuth too, but the login/session must be prepared before asking the agent to make changes.

For token-based agent auth:

```bash
export IMPLELOAD_AGENT_TOKEN=...
impleload --actor-email user@sytex.io activities list
impleload --actor-discord-user 123456789 worklogs list --activity-id 1
```

Rules for token-based agent mode:

- Always provide exactly one actor: `--actor-email` or `--actor-discord-user`.
- The installer may configure `IMPLELOAD_AGENT_TOKEN`, but the actor is still required per command unless `IMPLELOAD_ACTOR_EMAIL` or `IMPLELOAD_ACTOR_DISCORD_USER` is already set in the environment.
- Do not invent actors. Use the actor supplied by the user or a trusted system context.
- The actor is used for audit attribution, so it must represent the real user being acted for.

## Common Options

Global options:

```bash
--base-url <URL>        # backend URL; env: IMPLELOAD_BASE_URL
--output table|json    # table by default; use json for scripts/parsing
--actor-email <EMAIL>  # requires IMPLELOAD_AGENT_TOKEN
--actor-discord-user <ID>
```

Use `--output json` for automation and when you need stable ids or structured fields. Use table output only for human summaries.

## Activities

Activities represent implementation work for a client and carry load, scope, dates, optional implementer assignment, and active state.

Core commands:

```bash
impleload activities list [--active true|false] [--client-id ID] [--implementer-id ID]
impleload activities get ACTIVITY_ID
impleload activities create --client-id ID --label "Kickoff" --load-hours 2
impleload activities update ACTIVITY_ID --label "New label"
impleload activities delete ACTIVITY_ID
```

Useful create/update fields:

```bash
--implementer-id ID
--clear-implementer
--load-hours HOURS
--revenue-usd AMOUNT
--scope-hours HOURS
--scope-completed-hours HOURS
--start-date YYYY-MM-DD
--end-date YYYY-MM-DD
--active true|false
```

Business rules are enforced by the backend. Expect errors if `load_hours < 1`, capacity would be exceeded, ids do not exist, or dates/scope are invalid.

## Worklogs

Worklogs record weekly consumed hours and Markdown descriptions against an activity.

Core commands:

```bash
impleload worklogs list --activity-id ACTIVITY_ID
impleload worklogs get WORK_LOG_ID
impleload worklogs create --activity-id ACTIVITY_ID --week-start YYYY-MM-DD --hours 2 --description-md "Trabajo realizado"
impleload worklogs update WORK_LOG_ID --hours 3 --description-md "Ajuste de avance"
impleload worklogs delete WORK_LOG_ID
```

Use `--implementer-id ID` when the worklog should be attributed to a specific implementer. If omitted, backend behavior may use the activity assignment depending on the API rules.

## Safety Workflow

Before mutating data:

1. Resolve target ids with `list` or `get`.
2. Prefer `--output json` if you need to inspect exact ids or fields.
3. State the intended mutation in plain language when the action is destructive or externally visible.
4. Run the smallest command that performs the requested change.
5. Verify with `get` or `list` after create, update, or delete.

For deletes, only proceed when the user clearly requested deletion or the surrounding task provides explicit approval.

## Error Handling

If the CLI returns an API error, report the status/code/message and do not retry blindly. Common causes are missing auth, wrong `--base-url`, missing actor in agent mode, invalid ids, capacity constraints, or business validation failures.

If auth fails:

- Run `impleload auth whoami` for OAuth sessions.
- Check `IMPLELOAD_BASE_URL` matches the session backend.
- For token-based agent auth, check `IMPLELOAD_AGENT_TOKEN` and exactly one actor flag.

## Examples

Create an activity as an agent:

```bash
IMPLELOAD_AGENT_TOKEN=... impleload \
  --actor-email implementer@sytex.io \
  --output json \
  activities create \
  --client-id 1 \
  --implementer-id 2 \
  --label "Configuracion inicial" \
  --load-hours 4 \
  --scope-hours 10
```

Record weekly work:

```bash
impleload --output json worklogs create \
  --activity-id 42 \
  --week-start 2026-04-20 \
  --hours 2 \
  --description-md "Configuracion y validacion con cliente"
```
