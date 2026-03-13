---
name: issue
description: End-to-end issue workflow. Takes an issue description, Linear ID, Sentry link, or GitHub PR URL and handles everything from Linear creation to PR submission. Use agent teams.
argument-hint: <description | SYT-{id} | sentry-link | pr-url> [assignee:name]
---

# Issue Workflow — End to End

You are an orchestrator that resolves an issue from start to finish across the Sytex stack.

> **Requires sandbox mode.** This skill spawns agents with `mode: "bypassPermissions"` which is only safe when sandbox is enabled. If sandbox is not active, warn the user and stop.

## Stack

| Project  | Main worktree    | Repo           |
|----------|-----------------|----------------|
| backend  | `./back/master`  | `Sytex/sytex`  |
| frontend | `./front/master` | `Sytex/front`  |

- Branch naming: `SYT-{id}-{slug}` (no prefix)
- Base branch: `master` in all repos
- Worktrees: created via `just wt-new` as siblings of `master/` (e.g., `./back/SYT-123-slug/`)
- Each worktree is self-contained: backend runs its own Docker (sytex + proxy), frontend has symlinked node_modules

---

## Phase 1 — Setup (orchestrator does this directly)

### 1.1 Parse input

Extract from `$ARGUMENTS`:
- **Linear ID**: pattern `SYT-{number}`
- **GitHub PR URL**: pattern `github.com/{org}/{repo}/pull/{number}` — fetch the PR to get the branch name, then extract `SYT-{number}` from the branch
- **Sentry link**: any URL containing `sentry`
- **Assignee override**: `assignee:{name}`
- **Description**: everything else

**If a GitHub PR URL is provided:**
```bash
# Extract the Linear ID from the PR's branch name
pr_branch=$(gh pr view {pr_url} --json headRefName --jq '.headRefName')
# Extract SYT-{number} from branch name (e.g., SYT-8176-export-automation-templates → SYT-8176)
```
Use the extracted Linear ID for step 1.2.

### 1.2 Resolve Linear issue

**If Linear ID provided** (directly or extracted from PR/branch) → fetch the issue from Linear (use the numeric part).

**If NOT provided** → create:
1. Find the `SYT` team in Linear
2. Create a new issue with title derived from description

### 1.3 Assign

1. If `assignee:{name}` → search Linear users by name
2. Otherwise → `git config user.email` → match against Linear users
3. Update the issue assignee in Linear

### 1.4 Link Sentry (if applicable)

1. Extract issue ID from Sentry URL
2. Fetch Sentry issue details (use the `/sentry` skill: `~/.claude/skills/sentry/sentry --org <org> issue <id>` and `events <id> --full`)
3. Add as attachment on the Linear issue
4. Save Sentry context (stack traces, error messages) for the implementation agents

### 1.5 Branch name

`SYT-{id}-{slug}` where slug = short kebab-case from Linear title (max 5 words).

### 1.6 Check for existing work (resume support)

For each project, check state in this order:

```bash
cd {main_worktree}
git fetch origin
PARENT="$(dirname "$PWD")"

# 1. Worktree directory exists?
if [ -d "${PARENT}/{branch-name}" ]; then
  echo "WORKTREE_EXISTS"
# 2. Remote branch exists?
elif git rev-parse --verify origin/{branch-name} >/dev/null 2>&1; then
  echo "REMOTE_BRANCH_EXISTS"
else
  echo "NEW"
fi
```

**WORKTREE_EXISTS** → this is a **resume**. Skip creation, go straight to Phase 2.
The agent prompt should mention this is a continuation, and to review existing changes before making new ones:
```
git log master..HEAD --oneline   # see what's already done
git diff master --stat           # see current state of changes
```

**REMOTE_BRANCH_EXISTS** → the branch exists (likely has a PR already) but worktree was cleaned up. Recreate from the remote branch:
```bash
just wt-new {branch-name} origin/{branch-name}
```
Also check for existing PRs and fetch their comments:
```bash
pr_json=$(gh pr list --repo {repo} --head {branch-name} --json number,url,title,comments --jq '.[0]')
```
If a PR exists, pass PR comments to the agent so it can address feedback.

**NEW** → continue with 1.7 and 1.8.

### 1.7 Determine affected projects

Analyze issue description + Sentry context. If unclear, ask the user.

### 1.8 Create worktrees

**Order: frontend first, then backend** (backend needs the frontend port for `SYTEX_ANGULAR_FRONT_URL`).

For each affected project:
```bash
cd {main_worktree}
git fetch origin master
just wt-new {branch-name}
```

Worktree path will be: `{dirname(main_worktree)}/{branch-name}`

**When both projects are affected**, after creating both worktrees, wire them together:
```bash
# Read developer domain from ~/.sytex-dev
DEV_DOMAIN=$(grep '^SYTEX_DEV_DOMAIN=' ~/.sytex-dev | cut -d= -f2)

FRONT_PORT=$(./front/master/bin/wt-ports.sh {branch-name})
read -r BACK_HTTP BACK_HTTPS < <(./back/master/bin/wt-ports.sh {branch-name})

# 1. Inject SYTEX_ANGULAR_FRONT_URL into backend compose override (if not already set by wt-bootstrap)
grep -q 'SYTEX_ANGULAR_FRONT_URL' ./back/{branch-name}/compose.worktree.override.yaml || \
  sed -i '' '/ALFRED_SERVICE_URL/a\
      SYTEX_ANGULAR_FRONT_URL: https://'"${DEV_DOMAIN}"':'"${FRONT_PORT}"'
' ./back/{branch-name}/compose.worktree.override.yaml

# 2. Patch frontend environment to point to backend worktree
sed -i '' "s|apiUrl: '.*'|apiUrl: 'https://${DEV_DOMAIN}:${BACK_HTTPS}'|" \
  ./front/{branch-name}/src/environments/environment.ts

# 3. Restart backend sytex to pick up new env vars
cd ./back/{branch-name} && docker compose --profile master restart sytex
```

Report the assigned ports to the user after creation:
```bash
# Frontend: https://{DEV_DOMAIN}:{FRONT_PORT}
# Backend:  https://{DEV_DOMAIN}:{BACK_HTTPS}
```

### Environment setup notes

Backend worktrees inherit all env vars from master's `docker-compose.override.yml` (Firebase, DB creds, etc.) via the compose chain:
`docker-compose.yml` → `master/docker-compose.override.yml` → `compose.worktree.override.yaml`

The `wt-bootstrap` automatically reads `~/.sytex-dev` and sets:
- `VIRTUAL_HOST` — developer domain
- `SYTEX_CORS_ALLOWED_ORIGINS` — allows requests from developer domain + worktree HTTPS port

Frontend worktrees get `environment.ts` copied from master by `wt-bootstrap`, with `apiUrl` patched from `~/.sytex-dev`.

---

## Phase 2 — Delegate to project agents

For each affected project, spawn a **general-purpose agent** with `run_in_background: true` and `mode: "bypassPermissions"` that works inside the worktree. The agent receives:

1. The **full issue context** (Linear title, description, Sentry stack traces if any)
2. The **worktree path** to work in
3. The **project-specific instructions** from the agent prompt file
4. **PR comments** (if resuming an issue with an existing PR)

If multiple projects are affected, spawn agents **in parallel**.

### Agent prompt template

Use this as the base prompt for each agent, filling in `{variables}`:

```
You are working on Linear issue SYT-{id}: {title}

{issue_description}

{sentry_context_if_any}

{pr_comments_if_any}

## Your workspace

You MUST work inside this worktree: {worktree_path}
All git commands, file reads, and edits happen from this path.
Branch: {branch_name} (already created, already checked out in the worktree)

{project_specific_instructions}

Report back: what you changed, test results, PR URL.
```

### Project-specific agent instructions

For each project, read the corresponding prompt file and paste its FULL CONTENT into the agent prompt:

- **Backend**: [backend-agent-prompt.md](backend-agent-prompt.md)
- **Frontend**: [frontend-agent-prompt.md](frontend-agent-prompt.md)

**IMPORTANT**: Inline the full content of the prompt file into the agent prompt. Do NOT tell the agent to "read the skill file" — agents cannot invoke skills.

---

## Phase 3 — Wrap up

After all agents finish:

1. Collect results from each agent (changes made, test results, PR URLs)
2. Present a summary to the user with PR links
3. If any agent failed, report the failure and ask the user how to proceed

---

## Important notes

- **Each worktree is self-contained** — implementation, testing, commits, and PRs all happen in the worktree
- **Backend worktrees** have their own Docker services (sytex + proxy), sharing master's infrastructure (MySQL, RabbitMQ, Redis, Elasticsearch)
- **Frontend worktrees** share node_modules via symlink from master
- **Same branch name** across all repos for the same Linear issue
- **Agents work in parallel** when multiple projects are affected
- **Inline full agent prompt content** — agents cannot read skill files or invoke skills
- **Use `mode: "bypassPermissions"`** — safe because sandbox restricts what agents can do
- **If stuck**, ask the user rather than guessing
- **Sentry stack traces** are critical context — always pass them to agents
- **PRs go to `master`** — always
- **PR reviews MUST go through this workflow** — when the user asks to review a PR, spawn the project-specific agent with the self-review step (Step 3). After the agent finishes and commits fixes, post a PR comment summarizing the review and fixes applied. Never do a manual review by just reading the diff.
