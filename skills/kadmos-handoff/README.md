# Kadmos Handoff Skill

Hand the work you are doing locally over to **Kadmos** — the team's always-on box
on the Sytex VPN — so it keeps going after your machine is off, and follow it from
your terminal.

A handoff is a **durable background job**: it gets its own Discord thread, keeps
running turns until its **done check** passes, and posts the result there. Your
agent composes the continuation prompt from the session you are in; this CLI
enqueues it and reads it back.

The API is reachable on the **Sytex VPN only**.

## Getting a token

Type **`/token`** to the Kadmos bot in Discord — it DMs you a personal bearer
token. **`/token revoke`** kills it. There is **one active token per person**.

If you already installed the **kadmos-memory** (recall) skill, you need nothing
more: this skill falls back to that token and base URL automatically.

## Installation

```bash
./install.sh kadmos-handoff
```

You'll be asked for:

- **Kadmos Token** — optional (`KADMOS_HANDOFF_TOKEN`). Leave it empty to reuse the
  kadmos-memory token.
- **Kadmos Base URL** — defaults to `http://10.31.149.63:7832` (`KADMOS_HANDOFF_BASE_URL`).
- **Handoff Channel ID** — the Discord channel where handoff threads are opened;
  defaults to the team's `#development` channel (`KADMOS_HANDOFF_CHANNEL_ID`).

Test it:

```bash
./install.sh kadmos-handoff test
```

## Usage

```bash
# Connectivity + auth + scope check
bash ~/.claude/skills/kadmos-handoff/kadmos-handoff test

# Hand the current branch over: the prompt lives in a file, the check asks GitHub
bash ~/.claude/skills/kadmos-handoff/kadmos-handoff create \
  --title "SYT-1234 finish the retry logic" \
  --prompt-file /tmp/handoff.md \
  --done-check 'gh pr list --repo Sytex/sytex --head SYT-1234-retry-logic --json url --jq ".[0].url" | grep .'

# What is running right now
bash ~/.claude/skills/kadmos-handoff/kadmos-handoff list

# One job's state (and its result once it finished)
bash ~/.claude/skills/kadmos-handoff/kadmos-handoff status 1a2b3c4d

# Follow it: prints only what changed, exits when the job settles
bash ~/.claude/skills/kadmos-handoff/kadmos-handoff watch 1a2b3c4d --interval 60

# The Discord thread itself — what Kadmos and the humans said
bash ~/.claude/skills/kadmos-handoff/kadmos-handoff thread 1a2b3c4d

# Stop it
bash ~/.claude/skills/kadmos-handoff/kadmos-handoff cancel 1a2b3c4d
```

## Commands

| Command | Description |
|---------|-------------|
| `create --title <t> (--prompt <text> \| --prompt-file <path>)` | Enqueue a handoff job; prints the job id and the thread URL |
| `list` | Queued + running jobs, one line each, plus the box's job settings |
| `status <id>` | One job's full state; includes the result once terminal |
| `watch <id> [--interval <s>]` | Poll and print only what changed; exits when the job settles |
| `thread <id>` | The job's Discord thread transcript |
| `cancel <id>` | Request cancellation |
| `test` | Connectivity + auth + scope check |

`create` also takes `--folder <name>` (working directory on the box),
`--done-check '<shell line>'`, `--channel-id <id>`, `--provider` and `--model`.

## The done check

`--done-check` is a **read-only shell line** the supervisor runs after every turn.
Exit 0 means the deliverable exists, and the **last line of its stdout** is what
the job reports as delivered — so print the URL. A non-zero exit means the job runs
another turn instead of claiming success; a check that cannot run is never counted
as a failure.

```bash
# a pull request
gh pr list --repo Sytex/sytex --head <branch> --json url --jq '.[0].url' | grep .

# a pushed branch
git ls-remote --exit-code --heads origin <branch>

# a produced file
test -s <path> && echo <path>
```

Write it so it **fails before the job starts** — a check that already passes
verifies nothing.

## Job ids and statuses

Every command accepts the full 32-character job id or the 8-character short form
shown on the thread's status card. A short prefix only resolves against **active**
(queued/running) jobs; pass the full id for a job that already finished.

`queued` · `running` · `completed` · `failed` · `abandoned` · `resumed`.
`watch` exits 0 on `completed`/`resumed` and non-zero on `failed`/`abandoned`.
An `abandoned` job ran out of budget or was interrupted — replying `!resume` in its
Discord thread continues it.

## Notes

- The box works from **`origin`**: push your branch before handing it over, or the
  box cannot see your work.
- After a job finishes, replying in its Discord thread resumes the same session on
  the box. To continue locally: `git fetch && git checkout <branch> && git pull`.
- If a command cannot reach Kadmos, you are not on the **Sytex VPN**. If the token
  is rejected (401) or lacks the jobs scope (403), run `/token` again in Discord.

## Configuration

Credentials live in `~/.agent-skills/kadmos-handoff/.env`:

```
KADMOS_HANDOFF_TOKEN="..."                        # optional — falls back to KADMOS_MEMORY_TOKEN
KADMOS_HANDOFF_BASE_URL="http://10.31.149.63:7832"
KADMOS_HANDOFF_CHANNEL_ID="788211006203625483"
```

Run the installer to set or update them.
