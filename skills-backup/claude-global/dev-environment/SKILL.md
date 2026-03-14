---
name: dev-environment
description: >-
  Use this skill to create, list, or destroy development environments.
  Triggers on: "create a dev env", "spin up environment for branch X",
  "destroy devenv", "list dev environments", "devenv status".
  Creates full-stack worktrees (back + front) with running services.
version: 1.0.0
allowed-tools:
  - Bash(~/.claude/skills/dev-environment/*:*)
---

# Dev Environment Manager

Create, list, and destroy full-stack development environments. Each environment creates git worktrees for both back and front repos, starts all services (Docker for back, ng serve for front), and reports accessible URLs.

## User Context

Messages include a user identifier in the format: `[@username (id:USER_ID) | roles]`

Extract the numeric USER_ID for all commands. Guild ID and channel ID should be extracted from the message context.

## CLI Usage

```bash
~/.claude/skills/dev-environment/kadmos-devenv <command> [options]
```

## Commands

### create

Create a new development environment for a branch.

```bash
~/.claude/skills/dev-environment/kadmos-devenv create \
  --branch feature-xyz \
  --user-id 123456 \
  --guild-id 789 \
  --channel-id 456
```

Options:
- `--branch` (required): Branch name for the worktrees
- `--user-id` (required): Discord user ID
- `--guild-id` (required): Discord guild ID
- `--channel-id` (required): Discord channel ID

The command returns immediately with a creating status. Poll with `status` to check progress.

### status

Check the status of a specific environment.

```bash
~/.claude/skills/dev-environment/kadmos-devenv status <env_id>
```

### list

List all active development environments.

```bash
~/.claude/skills/dev-environment/kadmos-devenv list
```

### destroy

Destroy a development environment (stops services, removes worktrees).

```bash
~/.claude/skills/dev-environment/kadmos-devenv destroy <env_id>
```

## Workflow

1. User requests a dev environment for a branch
2. Run `create` with the branch name and user context
3. Poll `status` every 5-10 seconds until status is `running` or `failed`
4. Once running, report the URLs to the user:
   - Back HTTP: `http://localhost:<back_http_port>`
   - Back HTTPS: `https://localhost:<back_https_port>`
   - Front: `http://localhost:<front_port>`
5. When done, destroy the environment with `destroy`

## Guidelines

1. Always extract user_id, guild_id, and channel_id from the message context
2. Branch names should follow git naming conventions (no spaces)
3. If the environment already exists for a branch, the create command returns the existing one
4. Report URLs clearly when the environment is ready
5. Adapt language to match the user's language
