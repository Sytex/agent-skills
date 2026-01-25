---
name: issue-resolution
description: End-to-end workflow for resolving user-reported problems/bugs. Use when someone reports an issue, error, bug, or problem - whether it comes with a Sentry link, Linear issue, both, or neither.
disable-model-invocation: true
---

# Issue Resolution Workflow

Resolve user-reported problems safely and consistently. This workflow integrates Sentry, Linear, and GitHub.

## Operating Principles (Non-Negotiable)

- **Investigate first** - No blind fixes
- **Propose before acting** - Always explain the solution before implementing
- **Explicit confirmation required** - Only proceed after user says "go ahead"
- **Ensure tracking exists** - Every fix needs a Linear issue
- **Link Sentry↔Linear** - When both exist, cross-reference them
- **Branch naming** - Always include Linear issue ID in branch name
- **Reuse existing skills** - Check for available skills before performing actions

## Skill Reuse Requirement

Before performing any action, check if an existing skill can do it:

| Action | Check for skill |
|--------|-----------------|
| Sentry operations | `/sentry` |
| Linear operations | Use Linear MCP tools |
| Create commit | `/commit` |
| Create PR | `/pr` |
| Create changelog | `/changelog` |

If a skill exists, use it. Note which skill was used for traceability.

---

## Workflow Steps

### 1. Intake

Determine what was provided:
- Sentry issue/event link?
- Linear issue ID/link?
- Free-form description?

Ask only minimum questions needed to understand the problem. Don't interrogate.

### 2. Investigation (Read-Only)

Gather context without making changes:
- If Sentry provided: fetch issue details, stacktrace, affected users
- Search codebase for relevant code
- Check recent commits/changes
- Review logs if available

Produce:
- **Investigation summary**: What you found
- **Hypothesis**: Most likely root cause

### 3. Propose Solution

Adapt explanation to the requester:

**If requester is NOT a developer:**
- Explain in user terms (non-technical)
- Describe expected outcome
- Mention any operational steps needed

**If requester IS a developer:**
- Technical diagnosis
- Likely root cause
- Files/areas affected
- Implementation approach

### 4. Confirmation Gate

Ask explicitly:

> "Do you approve proceeding with this fix?"

If user does NOT approve:
- Stop implementation
- Ask what's missing or unclear
- Offer alternative approaches if applicable

**Do not proceed without explicit approval.**

### 5. Ensure Linear Issue Exists

Only after approval:

- If Linear issue exists → use it
- If not → ask: "Should I create a Linear issue, or do you have one?"

If creating a Linear issue, include:
- Clear title
- Description with repro steps
- Expected vs actual behavior
- Investigation summary
- Proposed fix

### 6. Sentry ↔ Linear Association

If Sentry issue exists:
1. Ensure Linear issue exists (step 5)
2. Add Sentry link to Linear issue (comment or description)
3. Add Linear issue link to Sentry (comment/annotation)

If both already exist, verify linkage. Add if missing.

### 7. Assignment Rules

**If requester IS a developer:**
- Assign Linear issue to requester
- Assign PR to requester (once created)

**If requester is NOT a developer:**
- Do NOT assign PR to them
- Record in both places: "Requested by: {name/role}"
- Ask: "Who should I assign this to?" (if not specified)
- Assign Linear issue and PR to the named developer

### 8. Branch Creation

Once Linear issue ID is known:
1. Create branch from `master` (or default branch)
2. Branch name MUST contain Linear ID

Format: `feature/SYT-{id}-{short-description}`

### 9. Implementation + PR

1. Implement according to approved plan
2. Use `/commit` skill to commit
3. Use `/pr` skill to create PR

PR must include:
- Linear issue link (always)
- Sentry issue link (if applicable)
- Apply assignment rules from step 7

### 10. Safe Stop Conditions

Stop and ask for clarification if:
- Issue is not reproducible
- Missing key information
- Requester says "just fix it" without context

Push back politely: "I need a bit more context to fix this safely. Can you tell me..."

---

## Output Checklist

After completing the workflow, report:

- [ ] Investigation summary + proposed solution
- [ ] Confirmation status (approved / not approved)
- [ ] Linear issue (existing / created) + link
- [ ] Sentry↔Linear association (if applicable)
- [ ] Branch name
- [ ] PR link + assignee
- [ ] Requester attribution (if non-dev)
- [ ] Skills used (which ones, for what)
- [ ] Next steps (if any remain)
