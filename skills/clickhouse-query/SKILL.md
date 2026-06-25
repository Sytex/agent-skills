---
name: clickhouse-query
description: Read-only access to the yulai event-tracking ClickHouse for ANY analytical question over product usage — HTTP requests and business actions. Use for who does what, how often, how fast, from where, trends over time, anomalies, and comparisons across users, orgs, and endpoints.
---

# ClickHouse Query Skill (yulai event store)

You have **read-only** access to the yulai event-tracking ClickHouse through the bundled
`clickhouse` executable. yulai captures, in near real time, two streams of events the Sytex
backend emits:

- `kind = 'request'` — one row per HTTP request: method, normalized path, status, latency.
- `kind = 'action'` — business events (task created/updated, form created, template updated…).

Everything lives in one table, **`events_raw`**, scoped by `tenant`. Production data is
`tenant = 'app.sytex.io'`.

Always assume the executable is **not** on `PATH`. Run it from this skill's directory (or by
absolute path):

```bash
./clickhouse help
./clickhouse test     # verify the connection
```

## This is an exploration tool, not a fixed report set

Treat `events_raw` as a fact table of "who did what, when, how fast". That answers a very
wide range of questions — the list below is **the shape of the space, not a menu of limits**:

- **Volume / traffic**: requests or actions over time; by user, org, workspace, endpoint,
  method, hour-of-day, day-of-week; busiest periods; growth/trend.
- **Behavior**: which endpoints a user or org actually uses; read vs write mix; which
  features (actions) people use; humans vs automated integrations; session patterns.
- **Performance**: latency distribution per endpoint (percentiles, tail); slowest routes;
  latency by org or over time.
- **Reliability**: error rates (`status_code >= 400`) by endpoint/user/org; error spikes.
- **Comparisons & anomalies**: org A vs org B; this week vs last; a single user vs the
  population; outliers and spikes.

ClickHouse is full SQL — use any aggregation, window function, percentile, regex, or date
function that fits. When unsure, **explore first**: `./clickhouse schema`, `./clickhouse
tenants`, `./clickhouse query "SELECT DISTINCT event FROM events_raw WHERE tenant='app.sytex.io' AND kind='action'"`,
or `SELECT min(ts), max(ts) FROM events_raw …` to see the time range.

## Commands

```bash
./clickhouse test                       # SELECT 1 connectivity check
./clickhouse schema                     # DESCRIBE events_raw
./clickhouse tables                     # list tables
./clickhouse describe <table>           # columns + types of a table
./clickhouse tenants                    # distinct tenants and row counts
./clickhouse query "<SQL>" [format]     # any read-only query
```

`format` is one of `pretty` (default, human table), `tsv`, `json`, `csv`.

Only read statements are accepted (`SELECT` / `WITH` / `SHOW` / `DESCRIBE` / `EXPLAIN`); the
wrapper rejects anything else.

## Schema: `events_raw`

The table with all the data:

| Column | Type | Notes |
|--------|------|-------|
| `tenant` | LowCardinality(String) | Leading sort key; **always filter** (`'app.sytex.io'` = prod). |
| `ts` | DateTime64(3) | Event timestamp (UTC). Use `toStartOfHour/Day`, `toHour`, etc. |
| `event` | LowCardinality(String) | Activity name, e.g. `task.updated` (mainly for actions). |
| `kind` | LowCardinality(String) | `'request'` or `'action'`. |
| `org_id` | UInt64 | Organization id (integer; no name lookup — see below). |
| `workspace_id` | UInt64 | Workspace id. |
| `user_id` | UInt64 | Acting user id; `0` = anonymous. |
| `email` | String | Acting user's email — the human-readable identity. |
| `session_id` | String | Front-end session id (often empty). |
| `event_id` | UUID | Unique per event. |
| `props` | JSON | Free-form; for requests holds only `sample_rate`. |
| `http_method` | LowCardinality(String) | Requests only. |
| `path` | String | **Already normalized** (`/api/task/{id}`) — ids collapsed. |
| `status_code` | UInt16 | Requests only. |
| `latency_ms` | UInt32 | Per-request duration (ms). |
| `idempotency_key` | String | Dedup key. |

Retention: hot 90d, tiered to cold storage at 90d, dropped at 365d.

### Empty tables (don't rely on them)

`dim_org_*`, `dim_user_*`, `dim_workspace_*`, `events_daily_agg`, `events_per_user_day`,
`user_tags`, and the `dict_*` dictionaries exist but are **not populated** — the producer
only emits raw events, not dimension snapshots or pre-aggregates. So:

- **No org-name / user-name lookup.** Identify orgs by `org_id`, people by `email`.
- Aggregate directly over `events_raw`; ignore the daily/per-user rollup tables.

## Things to know (so results are correct)

- Always include `WHERE tenant = 'app.sytex.io'`. A separate `prod-smoke` tenant carries
  healthcheck traffic you normally exclude.
- `path` is pre-normalized — no need to regex out ids.
- **Automated integrations skew "per person" stats.** They poll list endpoints around the
  clock; their emails match `%apisytex%` and `%@sytex.internal%` (machine-to-machine).
  Exclude them when measuring human behavior — or target them when the question is about
  integrations.
- Filter `user_id != 0` to drop anonymous traffic when you mean logged-in users.
- For latency, prefer **percentiles** (`quantile(0.5)/(0.95)/(0.99)`, `max`) over `avg()` —
  the tail is long and averages mislead.
- Tracking went live recently, so history is limited — check `min(ts)`/`max(ts)` before
  claiming long-range trends.

## Worked examples (patterns, not the menu)

Endpoints a given user hits, with latency tail and errors:

```bash
./clickhouse query "
SELECT http_method, path, count() AS requests,
       round(quantile(0.95)(latency_ms)) AS p95,
       countIf(status_code>=400) AS errors
FROM events_raw
WHERE tenant='app.sytex.io' AND kind='request' AND email='someone@example.com'
GROUP BY http_method, path ORDER BY requests DESC LIMIT 50"
```

Requests per active human per hour-of-day (bots excluded):

```bash
./clickhouse query "
SELECT toHour(ts) AS hour, count() AS requests, uniqExact(user_id) AS users,
       round(count()/uniqExact(user_id)) AS reqs_per_user
FROM events_raw
WHERE tenant='app.sytex.io' AND kind='request' AND user_id!=0
  AND email NOT LIKE '%apisytex%' AND email NOT LIKE '%@sytex.internal%'
GROUP BY hour ORDER BY hour"
```

Adapt the `WHERE` / `GROUP BY` / aggregates freely — these only show the idioms (tenant
filter, bot exclusion, percentiles, time bucketing). The right query is whatever answers the
question being asked.

## Safety

**Read-only.** Only `SELECT` / `WITH` / `SHOW` / `DESCRIBE` / `EXPLAIN`. Never `ALTER`,
`INSERT`, `DROP`, `OPTIMIZE`, or any DDL/DML against production. Schema changes go through
yulai's migration files and deploy pipeline, never ad-hoc queries. Treat all data as
sensitive and confidential.
