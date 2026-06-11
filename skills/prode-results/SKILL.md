---
name: prode-results
description: Sync FIFA World Cup 2026 match results from football-data.org into the prode Firestore, with dry-run and explicit confirmation. Use when the user asks to impactar/cargar/sincronizar resultados del prode o del mundial.
---

# Prode Results Sync

Sync WC2026 match results from football-data.org into the prode Firestore
collection (`worldCup2026/tournament/matches`) — the same collection the
mobile prode admin writes to. Once scores land there, the backend's
per-minute fingerprint task recomputes points and rankings automatically;
nothing else needs to be triggered.

The bundled `prode-results` executable is a self-contained script (runs via
`uv`). Always run it from this skill's directory or by absolute path:

```bash
./prode-results            # dry-run (default): print proposal, write NOTHING
./prode-results apply      # write the proposal to Firestore
./prode-results --json     # machine-readable report
```

## Safety rules — NON-NEGOTIABLE

1. **ALWAYS dry-run first.** Show the user the full proposal (score updates,
   team fills, unmatched warnings) before anything else.
2. **NEVER run `apply` without the user explicitly confirming in this
   conversation, after seeing the dry-run output.** "Apply" intent in an
   earlier session does not carry over.
3. Scores are only ever proposed for matches the API reports as **FINISHED**
   (final result including extra time, penalties excluded). The script
   enforces this — do not try to work around it for live matches.
4. If the dry-run shows any **UNMATCHED** lines, surface them prominently;
   they mean the API and Firestore disagree about the fixture and a human
   must look before applying.

## What the script proposes

- **Score updates**: FINISHED matches whose Firestore score differs (or is
  null). Shows old vs new score per match.
- **Team fills**: knockout matches resolved in the API bracket but still
  null in Firestore. These never affect points (the backend fingerprint
  ignores team identity).
- **Already in sync / skipped / unmatched** counts for transparency.

## Configuration

Env vars, or `KEY=VALUE` lines in `~/.agent-skills/prode-results/.env`:

| Key | Value |
|-----|-------|
| `FOOTBALL_DATA_API_TOKEN` | football-data.org token (free tier, registered at football-data.org/client/register) |
| `GOOGLE_SERVICE_ACCOUNT_FILE` | path to a Firebase service account JSON with Firestore access |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | alternative: the service account JSON inline |

If config is missing the script exits with a clear error — relay it to the
user instead of guessing values.

## Typical flow

1. User: "impactá los resultados del prode" (or a match just finished)
2. Run `./prode-results` (dry-run), show the output
3. User confirms → run `./prode-results apply`
4. Report what was written; points recompute happens automatically in the
   backend within ~1 minute
