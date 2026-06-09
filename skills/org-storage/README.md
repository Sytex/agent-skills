# Organization Storage

Report how much storage a Sytex organization is using — the sum of
`shared_file.file_size` (bytes) — as a human-friendly size (MB / GB / TB …).

This skill **does not connect to the database itself**. It delegates every query
to the read-only [`database`](../database) skill CLI, so it holds no credentials
and only ever issues `SELECT` queries.

## Prerequisites

- The [`database`](../database) skill installed and configured with a read-only
  connection to the target database (the helper looks for it at
  `~/.claude/skills/database/database`, `~/.codex/...`, `~/.gemini/...`, or on
  `PATH`).
- `python3`.

## Usage

The skill is normally driven by the agent (see `SKILL.md`), but the bundled
helper can be run directly:

```bash
# Resolve an org by id or partial, case-insensitive name (fast).
~/.claude/skills/org-storage/org-storage resolve "Telefonica"
~/.claude/skills/org-storage/org-storage resolve 100

# Sum storage for an org id (SLOW for large orgs — run in the background).
~/.claude/skills/org-storage/org-storage storage 100
```

### Options (after the subcommand)

| Flag | Meaning |
| --- | --- |
| `--db <slug>` | Force a specific `database` connection (skip auto-detect). |
| `--database <name>` | Force a specific database name. |
| `--timeout <secs>` | Wall-clock backstop for the slow sum (default `900`). |

## How it works

1. **Connection auto-detect.** The helper parses `database dbs` and prefers a
   read-only-looking connection (slug containing `reader`/`replica`/`ro`),
   falling back to the active/first one. It always reports the host it used so
   the read-only endpoint is auditable.
2. **Resolve** turns a name into candidates via
   `SELECT id, name FROM organizations_organization WHERE name LIKE '%…%'`, or
   validates a numeric id directly.
3. **Storage** first confirms the org exists (a fast id lookup), then runs the
   one slow query — `SELECT SUM(file_size) FROM shared_file WHERE
   organization_id = <id>` — and formats the byte total. `NULL` (an org with no
   files) is reported as `0 B`.

## Why two steps / async

Name resolution is instant and may need a human to disambiguate, so it runs in
the foreground. Summing file sizes can take a minute or more for the largest
organizations (the only usable index on `organization_id` isn't covering), so
the agent runs it in the background and reports back when it finishes.
