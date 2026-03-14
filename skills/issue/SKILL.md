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

Analyze issue description + Sentry context to determine which projects need **code changes**.

### 1.8 Create worktrees

**Always create worktrees for BOTH projects** (backend + frontend), even if only one needs code changes. This ensures the user can test end-to-end with the frontend pointing to the backend worktree.

Run the worktree creation script from the skill directory:

```bash
/home/ubuntu/projects/.claude/skills/issue/create-worktree.sh {branch-name}
```

The script handles everything: frontend worktree, backend worktree (with compose override patching for SSL certs and `SYTEX_ANGULAR_FRONT_URL`), starting backend containers, and launching `ng serve`.

It outputs the URLs at the end — **always report these to the user**.

### Environment setup notes

Backend worktrees inherit all env vars from master's `docker-compose.override.yml` (Firebase, DB creds, etc.) via the compose chain:
`docker-compose.yml` → `master/docker-compose.override.yml` → `compose.worktree.override.yaml`

The `wt-bootstrap` automatically reads `~/.sytex-dev` and sets:
- `VIRTUAL_HOST` — developer domain
- `SYTEX_CORS_ALLOWED_ORIGINS` — allows requests from developer domain + worktree HTTPS port

Frontend worktrees get `environment.ts` copied from master by `wt-bootstrap`, with `apiUrl` patched from `~/.sytex-dev`.

---

## Phase 2 — Delegate to project agents

For each project that needs **code changes** (determined in step 1.7), spawn a **general-purpose agent** with `run_in_background: true` and `mode: "bypassPermissions"` that works inside the worktree. Projects created only for testing (no code changes) don't get an agent — they just run as-is pointing to the other worktree.

Each agent receives:

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
