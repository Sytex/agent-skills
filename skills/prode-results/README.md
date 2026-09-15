# Prode Results Sync

Syncs FIFA World Cup 2026 match results from [football-data.org](https://www.football-data.org/) into the prode Firestore collection (`worldCup2026/tournament/matches`), the same collection the mobile prode admin writes to. The Sytex backend detects score changes automatically (per-minute fingerprint task) and recomputes user points and rankings — no extra trigger needed.

## Safety model

- `dry-run` is the default and writes nothing: it prints the proposed score updates, knockout team fills, and any API/Firestore mismatches.
- `apply` writes the proposal. Agents must always show the dry-run output and get explicit user confirmation first (see SKILL.md).
- Scores are only proposed for matches the API reports as **FINISHED** — final result including extra time, excluding penalties. Live or partial scores are never written.

## Usage

```bash
./prode-results            # dry-run (default)
./prode-results apply      # write to Firestore
./prode-results --json     # machine-readable report
```

The executable is a self-contained Python script run via [uv](https://docs.astral.sh/uv/) (declares its own dependencies).

## Configuration

Set in `~/.agent-skills/prode-results/.env` (or as environment variables):

| Key | Value |
|-----|-------|
| `FOOTBALL_DATA_API_TOKEN` | football-data.org token — free tier, register at https://www.football-data.org/client/register |
| `GOOGLE_SERVICE_ACCOUNT_FILE` | path to a Firebase service account JSON with Firestore access to the prode project |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | alternative to the above: the service account JSON inline |
