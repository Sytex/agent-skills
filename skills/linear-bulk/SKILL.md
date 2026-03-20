---
name: linear-bulk
description: Bulk-create Linear issues from a JSON file or inline data. Use when user wants to create multiple Linear issues at once, batch-create stories, or bulk-import issues.
allowed-tools:
  - Read
  - Bash(~/.claude/skills/linear-bulk/*:*)
  - Bash(~/.claude/skills/linear/*:*)
---

# Linear Bulk Issue Creator

Create multiple Linear issues at once from a JSON input, with optional parent issue grouping.

## Command

```bash
~/.claude/skills/linear-bulk/bulk-create <json-file> [options]
```

### Required

- `<json-file>` - Path to a JSON file with the issues to create

### Options

| Flag | Description | Example |
|------|-------------|---------|
| `--team <KEY>` | Team key (overrides per-issue teamKey) | `--team USX` |
| `--assignee <username>` | Assignee username or display name | `--assignee jc` |
| `--label <name>` | Label name to apply to all issues | `--label "Inet"` |
| `--parent-title <title>` | Create a parent issue and nest all as sub-issues | `--parent-title "Epic title"` |
| `--parent-description <desc>` | Description for the parent issue | `--parent-description "..."` |
| `--parent-priority <1-4>` | Priority for the parent issue (default: highest child priority) | `--parent-priority 2` |
| `--dry-run` | Validate input without creating issues | `--dry-run` |

## JSON Format

The input JSON file must have this structure:

```json
{
  "issues": [
    {
      "title": "Issue title (required)",
      "description": "Issue description (optional)",
      "priority": 2,
      "teamKey": "USX"
    }
  ]
}
```

- `title` (required): Issue title
- `description` (optional): Issue description, supports newlines
- `priority` (optional): 1=Urgent, 2=High, 3=Medium, 4=Low
- `teamKey` (optional): Team key per issue, overridden by `--team` flag

## User Input Format

When a user wants to bulk-create issues, ask them to provide:

1. **JSON file** (attached or inline) with the issues array
2. **Team** (`--team KEY`): Which Linear team to create them in
3. **Assignee** (`--assignee username`): Who to assign them to
4. **Label** (`--label name`): Label to tag all issues with
5. **Parent grouping** (optional): Whether to group under a parent issue

The skill will return the identifier (e.g. USX-1234) of each created issue.

## Examples

```bash
# Basic bulk create
~/.claude/skills/linear-bulk/bulk-create issues.json --team USX --assignee jc --label "Inet"

# With parent issue
~/.claude/skills/linear-bulk/bulk-create issues.json --team USX --assignee jc --label "Inet" \
  --parent-title "Epic: Feature X"

# Dry run to validate
~/.claude/skills/linear-bulk/bulk-create issues.json --team USX --assignee jc --dry-run
```

## Output

The script outputs one line per created issue:

```
PARENT: USX-1200 | Epic title
  #1:   USX-1201 | P2 | Issue title 1
  #2:   USX-1202 | P3 | Issue title 2
```

If `--dry-run` is used, it prints validation results without creating anything.
