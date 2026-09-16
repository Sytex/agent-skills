---
name: kadmos-handoff
description: FROM A DEVELOPER'S OWN MACHINE ONLY — hand the work in progress over to Kadmos so it keeps going on the team's always-on box after this machine is off, and follow it from here. Never use it from a session already running inside Kadmos (a prompt carrying "[Thread: https://discord.com/…]", "[Channel id: …]" or "[Job id: …]" context lines, or a working directory under /home/ubuntu/sytex-claude-workspace) — there the kadmos-background skill is the way to keep working. Use when the user says "handoff", "dejale esto a kadmos", "que lo termine kadmos", "me voy / se apaga la compu, seguí en kadmos", "seguilo en background en kadmos", "pasale esto a kadmos", or asks about a running handoff: "how is the kadmos job going", "qué está haciendo kadmos", "cómo va el job".
allowed-tools:
  - Read
  - Write
  - Bash(~/.claude/skills/kadmos-handoff/*:*)
  - Bash(git:*)
  - Bash(gh:*)
---

# Kadmos Handoff

From a developer's own machine only: hand the work in progress over to Kadmos so it keeps running on the team box after the laptop is off, and follow it from the terminal ("handoff", "dejale esto a kadmos", "cómo va el job de kadmos"). Never from a session already inside Kadmos.

Kadmos runs coding agents on an always-on box on the Sytex VPN. A **handoff** is a
durable background job there: it gets its own Discord thread, keeps running turns
until its **done check** passes, and posts the result in that thread. So work that
would die when this machine sleeps continues on the box.

This skill does two things: **hand work over**, and **answer "how is it going?"**.

**Where it runs:** on the developer's own machine. Inside Kadmos itself (the box
that runs this same org's skills — a prompt carrying `[Thread: …]`, `[Channel id: …]`
or `[Job id: …]` lines, or a working directory under `/home/ubuntu/sytex-claude-workspace`)
it makes no sense: a job handing off to Kadmos is Kadmos talking to itself; there, the
`kadmos-background` skill continues work.

## Running the executable

Run the `kadmos-handoff` script **through `bash`**, from this skill's directory —
it is installed without an execute bit and it is not on `PATH`:

```bash
bash ./kadmos-handoff help
```

If your working directory is not the skill directory, use the absolute path of the
script (the skill folder is `kadmos-handoff/` when installed from the agent-skills
repo, or `sytex-org-353-kadmos-handoff-<id>/` when installed from the Sytex org
catalog). This applies across all shell-based agent environments.

## Getting a token (tell the user this if not configured)

A teammate gets a personal token by typing **`/token`** to the Kadmos bot in
Discord — the bot DMs it back. If they already set up the **kadmos-memory**
(recall) skill, that token is reused automatically and nothing else is needed. If
a command reports the token was rejected (401) or lacks the jobs scope (403), tell
them to run `/token` again for a fresh one. If it cannot reach Kadmos at all, they
are **not on the Sytex VPN**.

# Part 1 — handing work over

Follow these steps in order. Do not skip step 2: **the box only ever sees
`origin`**, so unpushed work simply does not exist for it.

## 1. Capture the state

Read the world, not your memory of it:

```bash
git status --porcelain
git branch --show-current
git log origin/<base>..HEAD --oneline        # base: master (monorepo) / main (mobile)
gh pr view --json url,number,isDraft         # may fail — there may be no PR
```

From that, fix:

- **Repository** — `Sytex/sytex` for the monorepo (backend `back/`, frontend `front/`),
  `Sytex/mobile` for the app. Confirm with `git remote -v` rather than assuming.
- **Base branch** — `master` in `Sytex/sytex`, `main` in `Sytex/mobile`.
- **Linear issue** — the `SYT-{id}` prefix of a branch named `SYT-{id}-{slug}`. A branch
  with no such prefix is a plain branch; say so and use the plain-branch path below.
- **What exists already**: commits ahead of base, a PR (draft or not), pushed or not.

## 2. Never hand off unpushed work

- **Uncommitted changes** → commit them as a WIP commit and **tell the user exactly
  what you committed** (file list, one line). Do not stash, do not discard, do not
  leave them behind.
- **Untracked files** → read `git status` and decide per file; anything the work
  needs must be added, anything incidental must not.
- Then `git push -u origin <branch>`.
- **Nothing to push and no branch** → the handoff is prompt-only (research, an
  investigation, a question to answer). That is valid; there is just no branch
  clause in the prompt and the done check must be about something else.

## 3. Compose the continuation prompt

Write it to a file and pass `--prompt-file` — prompts are long and a file avoids
every shell-quoting trap. Write it in **English**, addressed to the agent that will
run on the box, and include every one of these:

**(a) The identity.** Linear issue, branch, repository, base branch, and the PR URL
when one exists.

**(b) Box-side setup.** The box's working directory is the team workspace
(`/home/ubuntu/sytex-claude-workspace`): the monorepo checkout is `mono/local`,
issue worktrees are siblings at `mono/SYT-{id}-{slug}/`, and mobile lives under
`mobile/`. The job starts at the workspace root, so:

- **A `SYT-{id}-{slug}` branch** — instruct it to run, from the workspace root:

  ```bash
  bash tools/issue-setup --slug <slug> --issue SYT-{id}          # --project mobile for the app
  ```

  It resolves the Linear issue and **detects the resume**: the remote branch already
  exists, so it recreates the worktree from it at `mono/SYT-{id}-{slug}/` instead of
  branching anew. It prints JSON — the prompt should tell the agent to read
  `worktree_path` and `resume_state` out of it and work in that worktree.

- **Any other branch** — no Linear issue, so no `issue-setup`. Fetch it and add a
  sibling worktree by hand:

  ```bash
  git -C mono/local fetch origin <branch>
  git -C mono/local worktree add ../<branch> origin/<branch>
  ```

- **Then register the worktree** with the background-jobs skill, as the run's first
  act — it is what keeps the workspace cleanup sweep off the tree, and what makes a
  cwd-dependent done check ask about the right directory:

  ```bash
  ~/.claude/skills/kadmos-background/kadmos-background register \
    --job-id <its own job id> --worktree-path <the worktree path>
  ```

  The job finds its own id in the `[Job id: …]` line Kadmos puts at the top of
  every turn's prompt — say so in the prompt, so it does not go looking elsewhere.

**(c) The check-before-create clause**, verbatim in spirit:

> Before creating anything, verify what already exists: `git log origin/<base>..HEAD`
> for commits, `git branch -r` for the branch, `gh pr list --repo <repo> --head <branch>`
> for a pull request. Reuse what is there; create only what these checks prove missing.

A job can be restarted by a deploy and replays its turn, so a prompt that blindly
creates opens a second branch and a second PR.

**(d) The work itself**, written from this session's actual context — not generic:

- what is **done** already (and therefore must not be redone),
- what is **left**, concretely, in order,
- **decisions already taken** and why, so the box does not relitigate them,
- **how to verify** (the exact test commands, the files involved),
- anything that failed and how, so it is not rediscovered from zero.

**(e) The exit contract** — one sentence stating what "finished" means, matching the
`--done-check` exactly. If the check is the PR check, the prompt must end in "open
the PR"; if it is the pushed-branch check, it must end in "commit and push".

## 4. Choose the done check

`--done-check` is a read-only shell line the supervisor runs after every turn.
**Exit 0 means the deliverable exists, and the last line of its stdout is what the
job reports as delivered** — so make it print the URL. A non-zero exit means the
work is not done: the job runs another turn in the same session instead of claiming
success. A check that cannot run at all is never treated as a failure.

Prefer a check that does not depend on the working directory.

- **The goal ends in a PR** (the common case):

  ```
  gh pr list --repo <repo> --head <branch> --json url --jq '.[0].url' | grep .
  ```

- **The goal is "finish the implementation and push"** — nothing uncommitted,
  nothing unpushed, something actually committed on top of base. Write it against
  the absolute worktree path so it is true wherever it runs:

  ```
  W=/home/ubuntu/sytex-claude-workspace/mono/<branch>; git -C $W diff --quiet && git -C $W diff --cached --quiet && git -C $W fetch -q origin <branch> && test -z "$(git -C $W log FETCH_HEAD..HEAD --oneline)" && git -C $W log origin/<base>..HEAD --oneline | grep -q . && echo "<branch> @ $(git -C $W rev-parse --short HEAD)"
  ```

- **Prompt-only work** — the deliverable is a file or a posted artifact:
  `test -s <path> && echo <path>`.

Rules: read-only, fast, and **specific enough to fail before the job starts**. A
check that already passes verifies nothing.

## 5. Title it

`--title` names the Discord thread, so make it findable:

- `SYT-1234 finish the retry logic` — issue id plus the goal, or
- `fix/webhook-parsing — finish and open the PR` — branch plus the goal.

## 6. Create it and tell the user

```bash
bash ./kadmos-handoff create \
  --title "SYT-1234 finish the retry logic" \
  --prompt-file <the file you wrote> \
  --done-check 'gh pr list --repo Sytex/sytex --head SYT-1234-retry-logic --json url --jq ".[0].url" | grep .'
```

Add `--folder <name>` only when the work is confined to a directory that **already
exists on the box** — a handoff that has to run `issue-setup` must start at the
workspace root, which is the default. `--channel-id` overrides the destination
channel; the default is the team's development channel.

Then tell the user, plainly:

- the **job id** (and its 8-character short form) and that it is **queued**, not yet running,
- the **Discord thread link** — the job's status card, its progress and its result all land there,
- that they can follow it **from here** (`watch` / `status` / `thread`) **or in the thread**,
- that after it finishes, **replying in that thread** (mentioning the bot, or replying
  to one of its messages) resumes the same session on the box,
- and that to continue **locally** they run `git fetch && git checkout <branch> && git pull`.

# Part 2 — following a handoff

| The user asks | Run |
|---|---|
| "how is it going?" / "cómo va?" | `bash ./kadmos-handoff status <id>` |
| "tell me when it finishes" / "avisame cuando termine" | `bash ./kadmos-handoff watch <id>` |
| "what is kadmos doing?" / "qué está haciendo?" | `bash ./kadmos-handoff status <id>`, then `thread <id>` for the detail |
| "what did it say?" / "qué dijo en el thread?" | `bash ./kadmos-handoff thread <id>` |
| "what is running?" / "qué hay corriendo?" | `bash ./kadmos-handoff list` |
| "stop it but keep what it has" / "frenalo y que entregue hasta donde llegó" / "pará y decime dónde quedó" | `bash ./kadmos-handoff wrapup <id>` |
| "cancel it" / "cancelalo" | `bash ./kadmos-handoff cancel <id>` — a **hard kill**: nothing committed, nothing saved. `wrapup` is the one that hands the work over |

**Wrap-up** stops the current turn and gives the job one last bounded turn in the
same session: it commits what is uncommitted as a `wip:` commit, pushes the branch,
and posts where it got to — what is done, what is left, where the work lives, and
any notes. The job then lands `abandoned` carrying `stopped by user` (shown as
`stopped (resumable)`), and a **`!resume`** reply in its Discord thread continues it
from that same session, so nothing is lost by stopping.

- **Ids**: every command takes the full 32-character id or the 8-character short
  form. A short prefix only resolves against **active** jobs — for a job that already
  finished, use the full id.
- **`status`** is the row: status, phase, progress line, elapsed, turns, cost,
  deliverable, error, and the result once terminal. **`thread`** is the conversation:
  what Kadmos posted and what people replied.
- **`watch`** prints a line only when something changes and exits when the job
  settles (non-zero on `failed`/`abandoned`). It is a foreground poll — use it when
  the user asked to be told, not as a default.
- Statuses: `queued` · `running` · `completed` · `failed` · `abandoned` · `resumed`.
  **`abandoned`** means it ran out of budget, was interrupted, or was stopped with
  `wrapup` — in every case it is resumable, and a reply of `!resume` in its Discord
  thread continues it.

## Reporting back

- **Answer in the user's language** (Spanish or English, matching how they asked).
- **Lead with the deliverable** — the PR or branch URL the check printed — then the state.
- **Never restate the job's own claims as verified.** The done check is the evidence;
  a job still running has proved nothing yet.
- Always include the thread link, so the user can read the run themselves.

## Scope & limits

- Only reachable on the **Sytex VPN**.
- The box works from `origin`. Anything not pushed is invisible to it.
- One handoff is one job: it does not adopt other work in the thread.
- This skill never merges, never deletes a remote branch and never lands anything —
  the job on the box is bound by the same rules.
