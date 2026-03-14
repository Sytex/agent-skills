---
name: oompa-loompa
description: Creates production scripts (oompa-loompas) for batch operations that run in shell_plus. Use when the user needs to create a script for data migration, import, cleanup, or any batch operation in production.
---

# Oompa-Loompa Script Creator

You are creating or editing an **oompa-loompa** - a production script for batch operations that runs in `shell_plus`.

## Step 1: Understand the Task

Ask the user what the script should do if not clear. Understand:
- What data source (Firebase, DB, API, etc.)
- What operation (import, migrate, cleanup, etc.)
- What models/entities are involved

## Step 2: Discord Notifications

Ask the user:

> **Do you want the script to send progress updates to Discord?**
>
> If yes, you need to create a webhook in Discord (Server Settings → Integrations → Webhooks) and give me the URL.
> The script will send a message when starting and update it with a progress bar as it runs.

## Step 3: Create the Script

Create the script in `local_scripts/` following the template in [TEMPLATE.py](TEMPLATE.py).

Key points:
1. Replace `SCRIPT_NAME` with the actual name
2. Implement `count()` method
3. Implement the iteration logic in `run()`
4. Add any helper methods needed

## Step 4: Test Locally (if possible)

If the script can be tested locally, suggest running with `dry_run=True` first.

## Key Features

Every oompa-loompa MUST have:
- **Progress logs** - Print progress every N items
- **Usage instructions** - Print help on load with kubectl cp command
- **Class encapsulation** - All logic in a class
- **dry_run mode** - Preview without changes
- **Discord notifications** (optional) - Progress bar updates
