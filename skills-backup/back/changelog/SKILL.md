---
name: changelog
description: Create a changelog fragment for the current branch changes
---

# Create Changelog Fragment

You are creating a changelog fragment for this project. Follow these steps:

## Step 1: Get Linear Issue ID

Check if you already know the Linear issue ID from the conversation context or branch name.

If not found, ask the user:
- "What is the Linear issue ID? (e.g., SYT-1234)"

## Step 2: Analyze Branch Changes

Run these commands to understand what changed:

```bash
git log master..HEAD --oneline
git diff master --stat
git diff master --name-only
```

Read the most relevant changed files to understand the changes.

## Step 3: Determine Fragment Type

Based on the changes, determine the type:
- `.feature.md` - New features
- `.improvement.md` - Improvements to existing features
- `.fix.md` - Bug fixes
- `.doc.md` - Documentation changes

If unclear, ask the user which type applies.

## Step 4: Get the Owner

Get the current GitHub username to use as owner:

```bash
gh api user --jq '.login'
```

Use this username as the owner in the changelog fragment.

## Step 5: Write the Fragment

Create a file at `changes/SYT-XXXX.{type}.md` with this format:

```markdown
{Title - Clear, user-friendly description of what changed}

{Description - 2-4 bullet points explaining the change in non-technical terms}

- UI changes: {yes/no}
- Business logic changes: {yes/no}
- Owner: @{github_username}
- Linear link: [SYT-XXXX](https://linear.app/sytex/issue/SYT-XXXX/)
```

## Writing Guidelines

- Write for end users and stakeholders, not developers
- Focus on WHAT changed and WHY it matters, not HOW it was implemented
- Avoid technical jargon (no "refactor", "repository", "use case", etc.)
- Use active voice and present tense
- Keep bullet points concise (one line each)
- Title should be a complete sentence describing the benefit

## Example

Good:
```markdown
Users can now track activity history on any entity

Added a new activity logging system that records changes across the platform:

- All create, update, and delete actions are now logged
- Users can see who made changes and when
- System-triggered and automation-triggered changes are also tracked

- UI changes: no
- Business logic changes: yes
- Owner: @{github_username}
- Linear link: [SYT-7480](https://linear.app/sytex/issue/SYT-7480/)
```

Bad (too technical):
```markdown
Add activity_logs module with repository pattern

Implemented ActivityLogRepository and CreateActivityLogUseCase following DI pattern:

- Added ContentType generic foreign keys for entity tracking
- Created ActorType and ActivityCategory enums
- Implemented get_by_entity and get_by_action_scope methods

...
```
