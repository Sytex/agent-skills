---
name: changelog
description: Write user-facing changelog entries using towncrier format. Use when asked to create a changelog, document a change, or write release notes.
---

# Changelog Writing

You are creating a user-facing changelog entry using towncrier format.

## Step 1: Gather Required Information

### Get Ticket ID

First, try to find the Linear ticket ID in the branch name:

```bash
git branch --show-current
```

If the branch follows the pattern `feature/SYT-123-...` or similar, extract the ticket ID.
If not found, ask: "What is the Linear ticket ID for this change? (e.g., SYT-123)"

### Get Owner

Try to infer the owner from git configuration:

```bash
git config user.name
```

If unclear, ask: "Who is the owner/developer responsible for this change? (Provide GitHub username)"

### Determine Category

Ask: "What type of change is this?"

- `feature` - New functionality or capabilities
- `improvement` - Enhancements to existing features
- `fix` - Bug fixes and issue resolutions

---

## Step 2: Gather Change Details

Ask the user to describe:

1. What changed?
2. Why does it matter to users?
3. Does it affect the UI? (yes/no)
4. Does it change business logic? (yes/no)

---

## Step 3: Create the Changelog File

### File Location

Create the file in: `changes/{TICKET-ID}.{category}.md`

Examples:

- `changes/SYT-123.feature.md`
- `changes/SYT-456.improvement.md`
- `changes/SYT-789.fix.md`

### Content Structure

```markdown
[Clear, user-friendly title]

[Brief description of what changed and why it matters to users]

- [Specific user benefit 1]
- [Specific user benefit 2]
- [Specific user benefit 3]

- UI changes: yes/no
- Business logic changes: yes/no
- Owner: @username
- Linear link: [TICKET-ID](https://linear.app/sytex/issue/TICKET-ID/)
```

---

## Writing Guidelines

### Language Rules

- **Write for end users, not developers**
- Use plain language, avoid technical jargon
- Focus on benefits and user impact
- Use active voice and present tense

**Good:** "You can now upload custom profile pictures"
**Bad:** "Implemented user avatar upload functionality"

### By Category

**Features:**

- Explain what the feature does
- Highlight key benefits
- Mention where to find the feature

**Improvements:**

- Describe the enhanced experience
- Quantify improvements when possible (e.g., "50% faster")

**Bug Fixes:**

- Describe the problem that was resolved
- Explain the improved behavior
- Avoid technical error details

---

## Examples

### Feature Example

```markdown
Advanced search filters for better content discovery

Find exactly what you're looking for with our new advanced search filters. You can now filter results by date, category, and custom tags to quickly locate specific content.

- Added date range filtering (last week, month, year, or custom dates)
- New category filters for documents, images, and videos
- Tag-based filtering with autocomplete suggestions

- UI changes: yes
- Business logic changes: yes
- Owner: @johndoe
- Linear link: [SYT-123](https://linear.app/sytex/issue/SYT-123/)
```

### Improvement Example

```markdown
Faster dashboard loading times

Your dashboard now loads significantly faster, especially for accounts with large amounts of data. Loading times have been reduced by up to 70%.

- Dashboard loading time reduced by up to 70%
- Improved responsiveness on mobile devices
- Smoother animations and transitions

- UI changes: no
- Business logic changes: no
- Owner: @janedoe
- Linear link: [SYT-456](https://linear.app/sytex/issue/SYT-456/)
```

### Bug Fix Example

```markdown
Resolved email notification delivery issues

Fixed several issues that were preventing email notifications from being delivered reliably. All notification types now send consistently.

- Email notifications now send consistently for all account activities
- Resolved issue where some users weren't receiving password reset emails
- Improved delivery success rate by 95%

- UI changes: no
- Business logic changes: yes
- Owner: @bobsmith
- Linear link: [SYT-789](https://linear.app/sytex/issue/SYT-789/)
```

---

## Review Checklist

Before finishing, verify:

- [ ] File is in `changes/` folder
- [ ] Filename: `{TICKET-ID}.{category}.md`
- [ ] Title is user-friendly
- [ ] Description is from user perspective
- [ ] Bullet points focus on user benefits
- [ ] UI changes field is accurate
- [ ] Business logic changes field is accurate
- [ ] Owner has @ prefix
- [ ] Linear link is properly formatted
