---
name: impleload
description: Operate Impleload through its official CLI for client activities, implementer capacity, scope, and dated worklogs. Use when a user asks to plan or assign client work, record work already performed, manage activities or worklogs, authenticate, or make audited agent-driven changes. Infer activity versus worklog from intent even when the user mixes the terms.
---

# Impleload CLI

Use the official `impleload` CLI to preserve backend validation and audit attribution. Prefer `--output json` when resolving ids or verifying changes.

## Interpret The Request

Do not classify the request from the words “activity” or “worklog” alone. Infer the business fact:

- Treat past work tied to a date, duration, or completed action as a **worklog**.
- Treat weekly planning, assignment, scope, contract dates, active state, or future work as an **activity**.
- Handle both separately when one request contains planning and performed work.
- Infer missing details only when the context supports one safe interpretation.
- If more than one plausible interpretation remains, ask the user to clarify before choosing an entity or executing a command. Never guess.

Examples:

- “Mi actividad de ayer fue el kickoff de Vista” means a worklog for the matching existing Vista activity, dated yesterday. Ask for the hours if missing or for the activity if several match.
- “Creá una actividad de kickoff para Vista con 2 horas semanales” means an activity with `load_hours = 2`.
- “Ayer hice el kickoff de Vista durante 1 hora” means a one-hour worklog with description `Kickoff`.
- “Cargá 2 horas para Vista” is ambiguous: ask whether this is weekly planned load or work already performed and, for performed work, ask for the date.

An activity holds the client work agreement and plan:

- `load_hours`: planned hours per week; it is not progress or consumed scope.
- `scope_hours`: total agreed hours.
- Optional implementer, start/end dates, and active state.

A worklog records work that happened:

- Existing activity, implementer, `work_date`, hours, and Markdown description.
- Worklogs consume scope; they do not reduce `load_hours`.
- `week_start` is derived from `work_date`; use `--work-date` for new operations.
- Never set `scope_completed_hours` or other derived progress fields directly.

Keep distinct non-contiguous work periods as separate worklogs unless the user explicitly asks to aggregate them.

## Authentication

Prefer `impleload` on `PATH`; otherwise use the dependency installer declared in `skill.json` or `$HOME/.local/bin/impleload`. Use `impleload --help` and subcommand help for the installed version.

If an installed skill-local `.env` exists, source it without displaying its contents:

```bash
set -a
source .env
set +a
```

Use either OAuth:

```bash
impleload auth login
impleload auth whoami
```

Or token-based agent authentication:

```bash
impleload --actor-email user@sytex.io --output json activities list
impleload --actor-discord-user 123456789 --output json worklogs list --activity-id 1
```

In agent mode, require `IMPLELOAD_AGENT_TOKEN` and exactly one real actor through `--actor-email`, `--actor-discord-user`, or its matching environment variable. Never invent an actor.

Distinguish identities:

- The actor identifies the real user on whose behalf the audited command runs.
- The activity/worklog `implementer_id` identifies who owns the plan or performed the work.
- When worklog `--implementer-id` is omitted, creation inherits the activity implementer. Supply it when someone else performed the work.

Use `--base-url` or `IMPLELOAD_BASE_URL` for non-default backends. Confirm the target backend before mutations.

## Commands

Activities:

```bash
impleload --output json activities list [--active true|false] [--client-id ID] [--implementer-id ID]
impleload --output json activities get ACTIVITY_ID
impleload --output json activities create --client-id ID --label "Kickoff" --load-hours 2 [--implementer-id ID] [--scope-hours HOURS]
impleload --output json activities update ACTIVITY_ID [--load-hours HOURS] [--scope-hours HOURS] [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD] [--active true|false]
impleload --output json activities delete ACTIVITY_ID
```

Use `--clear-implementer` to remove an activity assignment. The backend enforces ids, dates, `load_hours >= 1`, and implementer capacity.

Worklogs:

```bash
impleload --output json worklogs list --activity-id ACTIVITY_ID
impleload --output json worklogs get WORK_LOG_ID
impleload --output json worklogs create --activity-id ACTIVITY_ID --work-date YYYY-MM-DD --hours HOURS --description-md "Trabajo realizado" [--implementer-id ID]
impleload --output json worklogs update WORK_LOG_ID [--work-date YYYY-MM-DD] [--hours HOURS] [--description-md "Corrección"] [--implementer-id ID]
impleload --output json worklogs delete WORK_LOG_ID
```

Treat `--week-start` as a legacy alias. Do not use it in new commands.

The CLI cannot change a worklog's `activity_id`. To move one, copy it to the destination while preserving implementer, date, hours, and description; verify exact content and totals; then delete the source only after explicit approval.

## Safe Mutation Workflow

1. Resolve current ids and fields with `list` or `get`; JSON list responses use `{ "items": [...] }`.
2. For worklogs, confirm the activity matches the declared date and check implementer/date/activity/content duplicates.
3. Present the exact proposed changes and wait for explicit approval before production writes unless the user's current instruction already unambiguously authorizes those exact mutations.
4. Run the smallest required create, update, or delete command.
5. Read back each affected record and verify fields and totals.

For deletes or copy-then-delete migrations, require explicit approval. If a command fails, report its status/code/message and do not retry blindly; first check authentication, backend, actor, ids, and business constraints.
