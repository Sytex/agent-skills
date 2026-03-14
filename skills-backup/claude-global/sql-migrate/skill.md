---
name: sql-migrate
description: Generate raw SQL files from Django migrations for deployment reference. Use when the user wants SQL backup files before deploying migrations.
---

# Generate SQL Migration Files

Generate raw SQL from Django migrations and save them as `.sql` files for deployment reference. These files are useful as a safety net in case something breaks during deployment.

## Step 1: Identify Migrations

There are two modes:

### Mode A: User provides specific migrations

If the user specifies one or more migrations (e.g., `shared 0150_customfield_soft_delete` or a full path like `app/shared/migrations/0150_customfield_soft_delete.py`), use those directly. Extract `<app_label>` and `<migration_name>` (without `.py`) from the input.

### Mode B: All new migrations in the branch

If no specific migrations are given, find all migrations that are new compared to `master`:

```bash
git diff master --name-only -- '*.py' | grep '/migrations/' | grep -v '__pycache__'
```

Parse each result to extract `<app_label>` and `<migration_name>` (without `.py`).

If no new migrations are found, inform the user and stop.

## Step 2: Generate SQL for Each Migration

Use `docker compose exec` to run `sqlmigrate` for each migration:

```bash
docker compose exec sytex bash -c "cd app && python manage.py sqlmigrate <app_label> <migration_name>"
```

**IMPORTANT:**
- Do NOT use `--settings sytex.settings-tests` — use default settings (MySQL)
- Do NOT use `uv run` — run inside the Docker container directly
- Do NOT use `just bash -c` — it doesn't support passing `-c` to the container shell

## Step 3: Save SQL Files

Save each SQL output to `migrations_sql/<migration_name>.sql` (relative to the project root).

Add a comment header to each file:

```sql
-- Migration: <app_label>.<migration_name>
```

Create the `migrations_sql/` directory if it doesn't exist.

## Step 4: Summary

List all generated files with their paths.

## Example

For a migration at `app/shared/migrations/0150_customfield_soft_delete.py`:

```bash
docker compose exec sytex bash -c "cd app && python manage.py sqlmigrate shared 0150_customfield_soft_delete"
```

Saved to: `migrations_sql/0150_customfield_soft_delete.sql`

## Notes

- If Docker is not running, inform the user to start it with `docker compose up -d`
- If a migration fails to generate SQL, log the error and continue with the next one
- The `migrations_sql/` directory should be gitignored — these files are for local reference only
