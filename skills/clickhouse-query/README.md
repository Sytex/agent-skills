# ClickHouse Query Skill

Read-only HTTP client for the **yulai** event-tracking ClickHouse. Lets an AI agent answer
open-ended analytical questions over product usage — HTTP requests (`kind='request'`) and
business actions (`kind='action'`) — all stored in the `events_raw` table.

## What it does

- Run any read-only SQL against the yulai event store (full ClickHouse SQL).
- Inspect the schema, list tables, and see which tenants are present.
- Analyze traffic, user/org behavior, endpoint usage, latency tails, error rates, trends,
  and anomalies — see `SKILL.md` for schema and analysis guidance.

It talks to ClickHouse's **HTTP interface** with `curl` (the native protocol is typically
not exposed through load balancers), so no `clickhouse-client` binary is required.

## Safety

- **Read-only**: only `SELECT` / `WITH` / `SHOW` / `DESCRIBE` / `EXPLAIN` are accepted; the
  wrapper rejects writes and DDL.
- **No secrets in the repo**: the endpoint and credentials live in a local `.env`
  (git-ignored), filled in by the installer.
- Production data is confidential.

## Prerequisites

- `curl` (present on virtually every system).
- A ClickHouse user with read access, and the HTTP endpoint reachable from where the skill
  runs.

## Installation

```bash
./installer/install.sh clickhouse-query install
```

Or via web UI:

```bash
./installer/install.sh --web
```

## Configuration

The installer asks for:

- **ClickHouse HTTP endpoint** — base URL, e.g. `https://your-clickhouse-host` (no trailing
  slash).
- **Host header** (optional) — only when hitting an internal load-balancer DNS that routes
  by host; leave blank otherwise.
- **ClickHouse user** — default `default`.
- **ClickHouse password** — pull it from your secrets manager and paste it.
- **Default tenant** — for convenience commands; production is `app.sytex.io`.

These are stored in the skill's `.env` (chmod 600, not committed).

## Usage

Assume the executable is **not** on `PATH`; run it from the skill directory or by absolute
path.

```bash
./clickhouse help
./clickhouse test                       # connectivity check
./clickhouse schema                     # DESCRIBE events_raw
./clickhouse tables                     # list tables
./clickhouse describe events_raw        # columns + types
./clickhouse tenants                    # tenants and row counts
./clickhouse query "SELECT count() FROM events_raw WHERE tenant='app.sytex.io'"
```

### Output formats

`format` is a positional argument after the SQL: `pretty` (default), `tsv`, `json`, `csv`.

```bash
./clickhouse query "SELECT email, count() FROM events_raw WHERE tenant='app.sytex.io' GROUP BY email ORDER BY 2 DESC LIMIT 10" tsv
```

## Available commands

| Command | Description |
|---------|-------------|
| `test` | Connectivity check (`SELECT 1`) |
| `query <sql> [format]` | Run a read-only query (`pretty`/`tsv`/`json`/`csv`) |
| `tables` | List tables |
| `describe <table>` | Show a table's columns and types |
| `schema` | Describe the main `events_raw` table |
| `tenants` | List distinct tenants and row counts |
| `help` | Show help |

## Troubleshooting

- **`.env file not found`** — run the installer to configure the connection.
- **Connection fails** — verify the endpoint is reachable from this host, check the
  password, and run `./clickhouse test`. If the endpoint is an internal load balancer with
  host-based routing, set the optional **Host header**.
- **`only read-only queries are allowed`** — the query must start with `SELECT`, `WITH`,
  `SHOW`, `DESCRIBE`, or `EXPLAIN` and contain no write/DDL keywords.

## Support

For issues or feature requests, contact the Sytex team.
