---
name: issue-resolution
description: End-to-end workflow for resolving/fixing problems/bugs. Use when someone reports an issue, error, bug, or problem - whether it comes with a Sentry link, Linear issue, both, or neither.
---

# Issue Resolution Workflow (MANDATORY)

YOU MUST follow this workflow exactly. Do NOT skip steps. Do NOT deviate.

---

## STEP 1: Intake (REQUIRED)

Determine what was provided:
- Sentry issue/event link?
- Linear issue ID/link?
- Free-form description?

Ask only minimum questions needed to understand the problem.

---

## STEP 2: Investigation (REQUIRED)

Gather context WITHOUT making changes:
- If Sentry provided: fetch issue details, stacktrace, affected users
- Search codebase for relevant code
- Check recent commits/changes

YOU MUST produce:
- **Investigation summary**: What you found
- **Hypothesis**: Most likely root cause

Do NOT proceed to Step 3 until investigation is complete.

---

## STEP 3: Propose Solution (REQUIRED)

Present your findings and proposed fix to the user.

**If requester is NOT a developer:**
- Explain in user terms (non-technical)
- Describe expected outcome

**If requester IS a developer:**
- Technical diagnosis
- Likely root cause
- Files/areas affected
- Implementation approach

---

## STEP 4: Confirmation Gate (MANDATORY)

Ask explicitly:

> "Do you approve proceeding with this fix?"

**NEVER proceed without explicit user approval.**

If user does NOT approve: stop and ask what's missing.

---

## STEP 5: Ensure Linear Issue Exists (MANDATORY)

YOU MUST have a Linear issue before proceeding. This is NON-NEGOTIABLE.

- If Linear issue exists → use it
- If NOT → ask: "Should I create a Linear issue, or do you have one?"

If creating a Linear issue, include:
- Clear title
- Description with repro steps
- Investigation summary
- Proposed fix

**Do NOT proceed to Step 6 until Linear issue ID is confirmed.**

---

## STEP 6: Sentry ↔ Linear Association

If Sentry issue exists:
1. Add Sentry link to Linear issue (comment or description)
2. Add Linear issue link to Sentry (comment/annotation)

---

## STEP 7: Worktree Setup (MANDATORY)

YOU MUST work in a git worktree. Check if already in one: `git worktree list`

Once Linear issue ID is known:

1. Determine the default branch (`main` or `master`)
2. Update remote reference with full refspec:
   ```bash
   git fetch origin <default-branch>:refs/remotes/origin/<default-branch>
   ```
3. Create worktree with new branch:
   ```bash
   git worktree add ../<short-description> -b feature/SYT-{id}-{short-description} origin/<default-branch>
   ```
4. Work inside the worktree directory

If already in a worktree, create/switch to the feature branch from the updated remote.

Branch name format: `feature/SYT-{id}-{short-description}`

**IMPORTANT:** ALWAYS use the full refspec when fetching. NEVER use just `git fetch origin <branch>`.

**Do NOT proceed to Step 8 until you are in the correct worktree with the correct branch.**

---

## STEP 8: Implementation (REQUIRED)

Implement according to approved plan.

- Write the fix
- Write/update tests
- Run tests to verify

---

## STEP 9: Commit and PR (MANDATORY)

YOU MUST complete these steps. Do NOT stop before creating the PR.

1. Use `/commit` skill to commit
2. Use `/pr` skill to create PR

PR MUST include:
- Linear issue link (ALWAYS)
- Sentry issue link (if applicable)

**NEVER report completion without a PR link.**

---

## STEP 10: Final Summary (REQUIRED)

After ALL steps are complete, provide a brief summary:

- What was fixed (1-2 sentences)
- PR link
- Linear issue link
- Sentry issue link (if applicable)

---

## Verification Checklist

Before reporting success, verify:
- [ ] Linear issue exists
- [ ] Branch includes Linear ID
- [ ] Commit was created
- [ ] PR was created and link is provided
- [ ] Sentry↔Linear linked (if Sentry was involved)

**If ANY item is missing, you have NOT completed the workflow.**
