---
name: org-storage
description: >-
  Report how much storage (disk space / file data) an organization is using in
  Sytex, by summing shared_file.file_size and returning a human-friendly size.
  Use whenever someone asks how much storage, disk space, or file data an org /
  organization / customer / tenant is taking up — by org name OR id — e.g. "how
  much storage is org 1234 using", "storage used by Telefonica", "how big is
  Acme's file data", "disk usage for organization X", "which is bigger, org A or
  B". Delegates all querying to the read-only `database` skill; it never writes
  data. Do NOT use for general/ad-hoc database questions unrelated to an
  organization's storage usage — use the `database` skill directly for those.
argument-hint: <org-id | org-name>
allowed-tools:
  - Read
  - Bash(~/.claude/skills/org-storage/*:*)
  - Bash(~/.claude/skills/database/*:*)
---

# Organization Storage

Report the total storage an organization is using — the sum of
`shared_file.file_size` (bytes) for that org — converted to a friendly unit
(MB / GB / TB …).

You run as the **main agent** (no sandbox, no sub-agents). All database access is
delegated to the bundled helper, which in turn drives the read-only `database`
skill CLI — so every query is read-only by construction, and you never touch
credentials.

The bundled helper is at `~/.claude/skills/org-storage/org-storage`. It has two
subcommands: `resolve` (fast) and `storage` (slow). The split exists because
summing file sizes can take **a minute or more for large organizations** (tens
of millions of files), while resolving a name to an id is instant. Resolve in
the foreground; run the heavy sum in the **background** so the conversation stays
responsive — this is the dynamic, async experience we want.

## Workflow

### 1 — Resolve the organization (foreground, fast)

Take the org id or name from the user's request and run:

```bash
~/.claude/skills/org-storage/org-storage resolve "<id-or-name>"
```

The output starts with a `connection:` line (the DB connection + host used — keep
this; you'll surface it for auditability) and a `matches:` count, followed by one
`id<TAB>name` row per match. Decide based on the count:

- **0 matches** — tell the user no organization matched, and suggest checking the
  spelling or trying the numeric id. Stop.
- **exactly 1 match** — use that `id` and `name`. Continue to step 2.
- **multiple matches** — show the user the candidates as a short `id — name` list
  and ask which one they mean. Do not guess. Once they pick, continue.

### 2 — Compute storage (background, slow)

Kick off the sum in the background (set `run_in_background: true` on the Bash
call) so you can tell the user it's working instead of blocking:

```bash
~/.claude/skills/org-storage/org-storage storage <id>
```

Immediately tell the user something like: *"Looking up storage for **{name}**
(org {id}) — this can take a minute or two for large organizations. I'll report
back as soon as it's done."* Then let it run; you'll be notified when the
background command finishes.

### 3 — Report the result

When the background command completes, read its output and reply to the user. The
helper prints a ready-made summary sentence (the last line) plus structured
`bytes:` and `size:` lines and the `connection:` line. In your reply:

- **Lead with the number** in a friendly, non-technical way, including the raw
  byte count in parentheses so it's exact and auditable. Example:
  > **Telefónica** (org 100) is using **1.24 TB** (1,363,148,943,360 bytes).
- Mention which **read-only connection/host** the figure came from (one short
  line) so it's clear the query hit the read-only endpoint.
- Keep DB/SQL jargon out of the user-facing reply.

Handle the non-happy paths the helper signals, and relay them plainly:

- `org: <id> (not found)` — the id doesn't exist; say so (no sum is run).
- `0 bytes … (no files)` — the org exists but has no stored files. Report `0 B`.
- `timed out: …` — the org is too large to sum within the time limit; tell the
  user it's exceptionally large and offer to retry. (The helper accepts
  `--timeout <secs>` if you want to allow longer.)
- `error: …` — relay the gist (e.g. the `database` skill isn't configured).

## Notes

- **Read-only endpoint:** the helper auto-detects the connection from
  `database dbs`, preferring a read-only-looking one (slug containing
  reader/replica/ro), and reports the host it used. If the environment has a
  dedicated reader connection, it's chosen automatically; otherwise it uses the
  default. Always surface the host so the choice is visible.
- **Override the connection** if ever needed:
  `org-storage storage <id> --db <slug> --database <name>`.
- **Dependency:** this skill requires the `database` skill to be installed and
  configured (`~/.claude/skills/database/database`). If the helper reports it
  can't find that CLI, the `database` skill needs to be set up first.
- The query is, by design, exactly:
  `SELECT SUM(file_size) FROM shared_file WHERE organization_id = <id>`.
