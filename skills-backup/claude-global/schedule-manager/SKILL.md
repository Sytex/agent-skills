---
name: schedule-manager
description: >-
  Use this skill for Kadmos recurring jobs: "create a schedule", "schedule a task",
  "remind me every day", "run every week at", "list my schedules", "delete schedule",
  "show scheduled tasks", "cancel schedule". Triggers on cron/recurring/reminder requests.
  Do NOT use this for creating issues or tasks in project trackers (Linear, Jira, etc.).
version: 4.0.0
allowed-tools:
  - Bash(~/.claude/skills/schedule-manager/*:*)
---

# Schedule Manager

Manage scheduled tasks in Kadmos via CLI. Schedules reference reusable Tasks (prompt + title) and trigger them on a cron schedule.

## User Context

Messages include a user identifier in the format: `[@username (id:USER_ID) | roles]`

Extract the numeric USER_ID for all commands.

## CLI Usage

```bash
~/.claude/skills/schedule-manager/kadmos-schedules --user-id <USER_ID> [--guild-id <GUILD_ID>] <command>
```

## Commands

### list

List schedules for the user or all schedules.

```bash
# List user's schedules
~/.claude/skills/schedule-manager/kadmos-schedules --user-id 123456 list

# List ALL schedules (admin)
~/.claude/skills/schedule-manager/kadmos-schedules --all list
```

### create

Create a new schedule. Requires `--guild-id` (extract from context if available).

A schedule needs a **task** (reusable prompt). You can either:
- Provide `--prompt` (and optionally `--title`) to auto-create a task
- Provide `--task-id` to reference an existing task

```bash
# Create with inline prompt (auto-creates a task)
~/.claude/skills/schedule-manager/kadmos-schedules --user-id 123456 --guild-id 789 create \
  --channel-id 456 \
  --prompt "Task description for the agent" \
  --title "Daily Report" \
  --cron "0 9 * * 1-5" \
  --timezone "America/New_York" \
  --mentions '["111222333", "444555666"]'

# Create referencing an existing task
~/.claude/skills/schedule-manager/kadmos-schedules --user-id 123456 --guild-id 789 create \
  --channel-id 456 \
  --task-id "abc12345-..." \
  --cron "0 9 * * 1-5" \
  --timezone "America/New_York"
```

Options:
- `--channel-id` (required): Channel where results will be posted
- `--cron` (required): Cron expression in user's timezone
- `--timezone` (required): User's timezone (e.g., "Europe/London")
- `--task-id`: Reference an existing task by ID (alternative to --prompt)
- `--prompt`: Instructions for the agent when triggered (auto-creates a task)
- `--title`: Task title (used when auto-creating a task with --prompt)
- `--mentions`: JSON array of user/role IDs to mention when the schedule runs
- `--one-shot`: Run once then auto-delete

### delete

Delete a schedule by ID.

```bash
~/.claude/skills/schedule-manager/kadmos-schedules --user-id 123456 delete abc12345
```

### update

Update an existing schedule.

```bash
~/.claude/skills/schedule-manager/kadmos-schedules --user-id 123456 update abc12345 --enabled false
```

Options:
- `--prompt`: New task description (updates the linked task)
- `--title`: New task title (updates the linked task)
- `--cron`: New cron expression
- `--timezone`: New timezone
- `--enabled`: true/false to enable/disable
- `--mentions`: JSON array of user/role IDs to mention

## Execution Flow

When a schedule triggers:
1. The bot sends a status message: "`Task title` executing..."
2. The agent runs the task prompt with access to the `send-message` skill
3. The status message is updated to "`Task title` done (Xs)" or "failed (Xs)"

The agent decides whether to send messages, what to say, and who to mention — driven entirely by the task prompt. The executor automatically injects the channel ID, guild ID, and mentions into the agent's context.

## Cron Format

`minute hour day month day_of_week` (in user's timezone)

| Expression | Meaning |
|------------|---------|
| `0 9 * * *` | Daily at 9:00 AM |
| `0 9 * * 1-5` | Weekdays at 9:00 AM |
| `30 14 * * *` | Daily at 2:30 PM |
| `0 */2 * * *` | Every 2 hours |
| `0 9 1 * *` | First day of month at 9:00 AM |

## Critical Rules

### Timezone Handling

If user's timezone is unknown (not in context):
1. Ask for their timezone before creating schedules
2. Use the timezone in all cron interpretations

### Channel Requirement

Scheduled task results are sent to a channel. The user must specify one.
- Channel mentions appear as `<#123456789>` - extract the numeric ID
- If no channel specified, ask where to send results

### Guild ID

The guild_id is required for creating schedules. It should be available in the message context. If not found, ask the user.

### Mentions

The `--mentions` parameter defines who the agent CAN mention when sending messages. These IDs are injected into the agent's context so the task prompt can reference them.
- Pass a JSON array of user or role IDs: `--mentions '["123456789", "987654321"]'`
- User mentions appear as `<@USER_ID>` in Discord - extract the numeric ID
- Role mentions appear as `<@&ROLE_ID>` - extract the numeric ID (without the `&`)
- The schedule creator is NOT automatically included — add their user_id if they want to be mentioned
- The agent decides whether to actually mention them, based on the task prompt

## Writing Effective Prompts

The `--prompt` is the only context the agent receives when a schedule triggers. Write it as a self-contained instruction set, like a mini skill definition. A vague prompt produces vague results.

### Structure

Every prompt should include:

1. **Objective**: What the agent must accomplish
2. **Data sources**: Where to get the data (files, APIs, commands, URLs)
3. **Steps**: Specific actions to perform, in order
4. **Messaging**: When to send a message, what to say, and who to mention (if applicable)

### Messaging in Prompts

The agent has access to the `send-message` skill. The executor injects channel ID, guild ID, and mentions automatically. **The task prompt must define:**

- **Whether** to send a message (always, conditionally, or never)
- **What conditions** trigger a message (e.g., "only if there are relevant results")
- **What to include** in the message (summary, details, data)
- **Who to mention** — use `--mentions` when creating the schedule so the agent receives the mention targets

If the prompt says nothing about messaging, the agent won't send anything.

### Examples

Bad:
```
Check my emails and let me know
```

Good:
```
Objective: Check for relevant emails.

Steps:
1. Use the gmail skill to search inbox for unread emails from the last 24h
2. Filter by: emails from clients, invoices, or anything marked urgent

Messaging:
- If there are relevant emails: send a message to the channel mentioning me, with a brief summary of each
- If nothing relevant: do not send a message
```

Another example:
```
Objective: Report the health status of production infrastructure.

Steps:
1. Run `kubectl get pods -n production` to list pod status
2. Run `kubectl top nodes` to get CPU/memory usage
3. Check for any pods not in Running state or with restarts > 3

Messaging:
- Always send a message with a one-line status (healthy/degraded/critical)
- If degraded or critical: mention the team and list affected pods
- If healthy: keep it brief, no mentions needed
```

### Tips

- Use absolute paths for any file references
- Specify the tools or commands the agent should use
- Define what "success" looks like so the agent knows when it's done
- Keep it concise but complete — the agent has no prior context

## File References

When creating a schedule that references specific files:
1. Include absolute paths in the prompt
2. Example: "Analyze /home/user/data/sales.csv and send a summary"
3. Files are automatically protected from cleanup while the schedule exists

## Guidelines

1. Convert relative times ("in 2 hours", "tomorrow at 9am") to cron using the current time from context
2. Format results clearly for the user
3. Adapt language to match the user's language
4. Always confirm successful operations with the schedule ID
