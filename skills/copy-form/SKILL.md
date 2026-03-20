---
name: copy-form
description: Copy/complete form answers and files from one Sytex form to another when the items (entries) are the same or similar. Use when user wants to copy form data between forms, duplicate form answers, transfer form responses, or create a new form from a template and populate it with data from an existing form.
version: 1.0.0
allowed-tools:
  - Bash(~/.claude/skills/copy-form/*:*)
  - Read
---

# Copy Form Skill

Copies answers, files, project, and metadata from one Sytex form to another when the form entries (items/questions) match by label.

## Usage

```bash
~/.claude/skills/copy-form/copy-form \
  --base-url https://app.sytex.io \
  --org 217 \
  --source-form 7363486 \
  --template 6539 \
  --task 3700661
```

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `--base-url` | Sytex instance URL (e.g., `https://app.sytex.io`) |
| `--org` | Organization ID |
| `--source-form` | ID of the form to copy FROM |
| `--template` | ID of the form template to create the new form FROM |
| `--task` | ID of the task to associate the new form TO |

### Optional Parameters

| Parameter | Description |
|-----------|-------------|
| `--target-form` | If provided, copies INTO an existing form instead of creating a new one |
| `--dry-run` | Show what would be copied without making changes |
| `--skip-files` | Skip file copying (only copy text answers) |
| `--skip-create` | Don't create a new form, only useful with `--target-form` |

## What It Does

1. **Reads** the source form's answers and files via API
2. **Creates** a new form from the specified template (unless `--target-form` is provided)
3. **Copies metadata**: project, sites, supplier, assigned user, reviewer, description
4. **Matches entries** between source and target by label text (fuzzy match)
5. **Copies answers**: text values, yes/no selections, etc.
6. **Copies files**: downloads from source and uploads to target answer entries

## How Entry Matching Works

Entries are matched between source and target by comparing their `label` text. The matching is case-insensitive and ignores extra whitespace. If a label exists in both forms, the answer (and files) are copied. Unmatched entries are reported but skipped.

## Examples

```bash
# Create new form from template and copy data from existing form
~/.claude/skills/copy-form/copy-form \
  --base-url https://app.sytex.io --org 217 \
  --source-form 7363486 --template 6539 --task 3700661

# Copy into an existing target form
~/.claude/skills/copy-form/copy-form \
  --base-url https://app.sytex.io --org 217 \
  --source-form 7363486 --target-form 7372868

# Preview what would be copied
~/.claude/skills/copy-form/copy-form \
  --base-url https://app.sytex.io --org 217 \
  --source-form 7363486 --template 6539 --task 3700661 --dry-run
```
