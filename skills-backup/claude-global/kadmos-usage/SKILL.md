---
name: kadmos-usage
description: >-
  Use this skill when users ask about THIS BOT's own usage: "how much have we spent",
  "who uses the bot the most", "kadmos stats", "bot usage", "our costs",
  "token consumption", "topics breakdown", "how many operations".
  This covers only Kadmos operation history. Do NOT use for project metrics,
  Linear stats, Sytex data, or any other external system.
version: 1.0.0
allowed-tools:
  - Bash(~/.claude/skills/kadmos-usage/*:*)
---

# Kadmos Usage Metrics

You are Kadmos. This skill lets you query your own usage data: how many operations you've run, costs, token consumption, who's been using you, and what topics you've worked on.

## CLI Usage

```bash
~/.claude/skills/kadmos-usage/kadmos-metrics <command> [options]
```

## Commands

### summary

Your overall usage summary. Optionally filter by period and/or user.

```bash
# All-time summary
~/.claude/skills/kadmos-usage/kadmos-metrics summary

# Last week, specific user
~/.claude/skills/kadmos-usage/kadmos-metrics summary --period week --user-id 123456
```

### users

Ranking of users by cost and operations.

```bash
# Top 10 users this month
~/.claude/skills/kadmos-usage/kadmos-metrics users --period month

# Top 5 users all time
~/.claude/skills/kadmos-usage/kadmos-metrics users --limit 5
```

### topics

Breakdown of your operations by topic.

```bash
~/.claude/skills/kadmos-usage/kadmos-metrics topics --period week
```

### roles

Breakdown by Discord user role.

```bash
~/.claude/skills/kadmos-usage/kadmos-metrics roles --period month
```

### features

Feature adoption statistics (cancellations, silenced messages, thread types).

```bash
~/.claude/skills/kadmos-usage/kadmos-metrics features --period week
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--period` | Time period: `day`, `week`, `month`, `all` | `all` |
| `--user-id` | Filter by Discord user ID (summary only) | — |
| `--limit` | Max results (users only) | `10` |

## Guidelines

1. Present data clearly with formatting appropriate for Discord
2. Format currency as `$X.XX` and large token counts with thousands separators
3. Adapt language to match the user's language
4. When asked vague questions like "how much are we spending", use the `summary` command
5. When asked "who uses it the most", use the `users` command
6. Combine multiple commands when needed for comprehensive reports
7. The `users` endpoint returns `user_name` for each user. Always display user names instead of raw Discord IDs
