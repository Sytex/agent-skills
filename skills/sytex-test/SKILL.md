---
name: sytex-test
description: Run Sytex backend tests (unit and integration). Use when user asks to run tests, verify changes, or check if code works.
allowed-tools:
  - Read
  - Bash(docker-compose:*)
  - Bash(docker:cp:*)
  - Bash(just:unit_test:*)
  - Bash(just:test:*)
---

# Sytex Backend Test Runner

Run unit and integration tests for the Sytex backend.

## Prerequisites

1. Docker Compose services must be running:
```bash
docker-compose up -d
```

2. For integration tests, copy test database to container:
```bash
docker cp tests/test_db_sqlite.sqlite <container-name>:/home/docker/code/app/test_db_sqlite.sqlite
```

## Test Types

| Type | Command | Database | Speed |
|------|---------|----------|-------|
| Unit | `just unit_test` | SQLite in-memory | Fast |
| Integration | `just test` | Pre-populated SQLite | Slower |

## Commands

### Unit Tests
```bash
# Module
just unit_test chat

# Specific file
just unit_test chat.tests.test_create_chat_use_case

# Multiple files
just unit_test chat.tests.test_create_chat_use_case chat.tests.test_send_message_use_case
```

### Integration Tests
```bash
# Module
just test chat

# Specific file
just test chat.tests.test_chat_viewset
```

## Test Locations

- Domain tests: `app/{domain}/tests/`
- AI tools tests: `app/{domain}/tests/ai_tools/`

## Troubleshooting

### "no such table" on unit tests
Some modules have ORM at import time. Use specific test files or integration tests.

### Integration tests fail
Copy test database first:
```bash
docker cp tests/test_db_sqlite.sqlite <container>:/home/docker/code/app/test_db_sqlite.sqlite
```
