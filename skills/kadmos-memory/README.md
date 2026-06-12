# Kadmos Memory Skill

Query **Kadmos memory** — the history of Discord messages the Kadmos bot
captures across the Sytex team's channels and threads. Use it to recall what was
discussed, who said what, what someone worked on, and what is still pending.

Read-only HTTP API, reachable on the **Sytex VPN only**. Privacy is enforced
server-side from your personal token: private threads only appear if you took
part.

## Getting a token

Type **`/token`** to the Kadmos bot in Discord — it DMs you a personal bearer
token. **`/token revoke`** kills it. There is **one active token per person**.

## Installation

```bash
./install.sh kadmos-memory
```

You'll be asked for:

- **Kadmos Token** — from `/token` in Discord (saved as `KADMOS_MEMORY_TOKEN`).
- **Kadmos Base URL** — defaults to the production address
  `http://10.31.149.63:7832` (`KADMOS_MEMORY_BASE_URL`).

Test it:

```bash
./install.sh kadmos-memory test
```

## Usage

```bash
# Connectivity + auth check
~/.claude/skills/kadmos-memory/kadmos-memory test

# What was I working on this month?
~/.claude/skills/kadmos-memory/kadmos-memory conversations --author me --after 2026-06-01T00:00:00Z

# Full-text search (FTS5: OR / AND / NOT, "quoted phrases"), both languages
~/.claude/skills/kadmos-memory/kadmos-memory search "permisos OR permissions" --after 2026-06-01T00:00:00Z

# Full ordered transcript of one conversation
~/.claude/skills/kadmos-memory/kadmos-memory transcript 1234567890123456789

# Activity in a time range
~/.claude/skills/kadmos-memory/kadmos-memory window --after 2026-06-01T00:00:00Z --before 2026-06-08T00:00:00Z
```

## Commands

| Command | Description |
|---------|-------------|
| `search <query> [flags]` | Full-text message search (FTS5) |
| `conversations [flags]` | Conversation summaries, newest activity first |
| `transcript <conversation_id>` | Full ordered transcript of a conversation |
| `window --after <ISO> [--before] [--author]` | Conversations active in a time range |
| `test` | Connectivity + auth check |

Common flags: `--author` (Discord id, name substring, or `me`), `--after` /
`--before` (ISO8601 **UTC**), `--limit`, `--source`, `--channel`,
`--conversation`, `--include-bot` (search only), `--q` (conversations only).

## Notes

- **Time is UTC.** The team is mostly UTC-3 — convert local times first.
- **Discord links:** `https://discord.com/channels/{space_id}/{conversation_id}`.
- History begins **June 2025** and only covers channels the bot can read.
- If a command can't reach Kadmos, you're not on the **Sytex VPN**. If the token
  is rejected (401), get a fresh one with `/token`.

## Configuration

Credentials live in `~/.agent-skills/kadmos-memory/.env`:

```
KADMOS_MEMORY_TOKEN="..."
KADMOS_MEMORY_BASE_URL="http://10.31.149.63:7832"
```

Run the installer to set or update them.
