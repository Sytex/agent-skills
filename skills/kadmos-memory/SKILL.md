---
name: kadmos-memory
description: Query Kadmos memory — the history of Discord messages the Kadmos bot captures across Sytex team channels and threads. Use for recall/memory questions about team Discord activity: "en qué estuve trabajando", "qué hablamos sobre X", "qué tengo pendiente", "ponéme al día", "what did we discuss", "catch me up", "what do I owe", "remind me what we said about <client/topic>".
allowed-tools:
  - Read
  - Bash(~/.claude/skills/kadmos-memory/*:*)
---

# Kadmos Memory

You can recall the **history of Discord messages the Kadmos bot captures** across
the Sytex team's channels and threads. Use this to answer memory / catch-up
questions: what someone worked on, what was discussed about a topic or client,
what is still pending, and who said what.

The data is read over a read-only HTTP API on the Sytex VPN. **Privacy is enforced
server-side** from the caller's personal token — private threads only appear if
that person took part. You never need to filter for privacy.

## Running the executable

Assume the `kadmos-memory` executable is **not** on `PATH`. Run it from this
skill's directory:

```bash
./kadmos-memory help
```

If your working directory is not the skill directory, use the absolute path to
the skill's `kadmos-memory` executable. This applies across all shell-based agent
environments.

## Getting a token (tell the user this if not configured)

A teammate gets a personal token by typing **`/token`** to the Kadmos bot in
Discord — the bot DMs it back. **`/token revoke`** kills it; there is one active
token per person. The token is saved via the installer
(`KADMOS_MEMORY_TOKEN`). If a command reports the token was rejected (401), tell
the user to run `/token` again for a fresh one. If it can't reach Kadmos, the
user is **not on the Sytex VPN**.

## Commands

All commands: `./kadmos-memory <command> [flags]`

### search — full-text message search

```bash
./kadmos-memory search "<query>" [flags]
```

| Flag | Description |
|------|-------------|
| `--author <X>` | Discord numeric id, case-insensitive **name substring**, or the literal `me` (the asking person, resolved from the token) |
| `--channel <id>` | Filter by channel id |
| `--conversation <id>` | Filter by conversation / thread id |
| `--source <s>` | Filter by source |
| `--after <ISO>` / `--before <ISO>` | ISO8601 **UTC** time bounds |
| `--include-bot` | Include messages authored by bots (excluded by default) |
| `--limit <n>` | Max results (default 100, max 500) |

`query` is **SQLite FTS5**: supports `OR`, `AND`, `NOT` and `"double-quoted phrases"`.
Hostile input is sanitized server-side, so a query never errors.

Returns `{"messages": [...], "count"}`. Each message:
`source, external_id, space_id, channel_id, channel_name, conversation_id,
conversation_name, author_id, author_name, is_bot, content, attachments,
created_at, is_private` (ids are strings).

### conversations — conversation summaries

```bash
./kadmos-memory conversations [--author X] [--q "<query>"] [--after ISO] [--before ISO] [--limit N]
```

Conversation summaries ordered by **last activity**, limit default 50. Each:
`conversation_id, conversation_name, channel_id, channel_name, space_id,
message_count, participants, first_at, last_at, is_private, snippet`.

### transcript — full ordered conversation

```bash
./kadmos-memory transcript <conversation_id> [--source S]
```

Returns the full ordered transcript: `{"thread"/"conversation": {...}, "messages": [...]}`.

### window — activity in a time range

```bash
./kadmos-memory window --after <ISO> [--before <ISO>] [--author X] [--limit N]
```

Convenience over `conversations` for "what happened between these dates".

### test — connectivity + auth

```bash
./kadmos-memory test
```

## Query playbooks

### (a) Activity summary — "en qué estuve trabajando" / "what was I working on"

Use the asking person via `--author me`:

```bash
./kadmos-memory conversations --author me --after 2026-06-01T00:00:00Z
```

Group by conversation, summarize each in a sentence, and link every one. For
another person, pass their name substring: `--author "pablo"`.

### (b) Topic / client recap — "qué hablamos sobre X" / "what did we discuss about X"

1. FTS search for the topic, trying **both languages** and `OR` alternates:
   ```bash
   ./kadmos-memory search "permisos OR permissions OR roles" --after 2026-05-01T00:00:00Z
   ```
2. Take the top conversations from the hits and pull their transcripts:
   ```bash
   ./kadmos-memory transcript <conversation_id>
   ```
3. Synthesize: what was decided, open questions, who was involved. Link each thread.

### (c) Pending / commitments — "qué tengo pendiente" / "what do I owe"

1. Pull the user's recent messages and the surrounding transcripts:
   ```bash
   ./kadmos-memory conversations --author me --after <recent ISO>
   ./kadmos-memory transcript <conversation_id>   # for each active one
   ```
2. From the transcripts, extract **promises the user made** ("yo lo hago", "I'll
   take it", "te paso", "lo reviso") and **asks others are waiting on from them**.
3. Output a **checklist**: each item = **what** + **who** is waiting + **thread link**.

### (d) Catch-up digest — "ponéme al día" / "catch me up"

```bash
./kadmos-memory conversations --after <since ISO> --limit 50
```

Summarize the most active conversations since the user was last around, grouped
by channel, each with a one-line summary and a link. Surface anything that
@mentions or addresses the user first.

## Time ranges

`--after` / `--before` are **ISO8601 UTC** (e.g. `2026-06-01T00:00:00Z`). The team
is mostly **UTC-3**, so convert the user's local times before querying (e.g.
"since Monday 9am" → add 3 hours for UTC). When the user is vague ("last week",
"esta semana"), pick a sensible UTC window and state it in the answer.

## FTS tips

- Try **both languages** — the team writes in Spanish and English. Use `OR`:
  `"factura OR invoice OR billing"`.
- Quote multi-word phrases: `'"task template"'`.
- Combine: `'"no aparece" OR "missing" AND permisos'`.
- Broaden if a search returns nothing; narrow with `--author` / time bounds if too much.

## Output rules

- **Answer in the user's language** (Spanish or English, matching how they asked).
- **Always link** conversations: `https://discord.com/channels/{space_id}/{conversation_id}`.
- **Cite who said what** — attribute claims to `author_name`, don't blur voices together.
- For commitments, always pair **what** with **who** and the **thread link**.

## Scope & limits

- History begins **June 2025**; there is nothing before that.
- Only covers **channels the Kadmos bot can read** — DMs and channels it isn't in
  are invisible.
- Read-only: this skill never posts to Discord.
- If `test` fails to connect, the user is not on the Sytex VPN.
