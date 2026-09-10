---
name: oompa-loompa
description: Creates, validates, and operates audited production batch scripts in Django shell_plus. Use for one-off migrations, imports, backfills, cleanups, and reconciliations that may change production data; not for product code changes or ordinary read-only reporting.
---

# Oompa-Loompa

Build production scripts that are safe to preview, apply, resume, and audit.

## Non-negotiable controls

- `run()` must default to dry-run and loading the script must not change business data.
- Advance autonomously through planning, implementation, local validation, checksum, preflight, dry-run, S3 audit readback, and other read-only reconciliation.
- Immutable source and audit uploads under the designated Oompa S3 prefix are permitted operational evidence; no other external side effect is implicit.
- Obtain explicit approval immediately before a mutating canary and a separate approval before full apply. Approval for investigation, dry-run, or canary does not authorize broader writes.
- Stop for unresolved precedence, destructive or out-of-scope effects, failed safety checks, or uncertain execution state. After a timeout, inspect the existing run before retrying.
- Notifications are opt-in. Do not ask for Discord by default, embed credentials, or make notification delivery a run dependency.

## Create or edit a script

1. Define organization, eligibility, exclusions, source of truth, conflict precedence, expected actions, review conditions, and independent verification.
2. Treat structural presence and meaningful content separately; an existing relation, reference, or document can still be empty.
3. Decide explicitly whether automation configuration is only authoritative context, whether persisted effects must be emulated, or whether external actions are in scope.
4. Generate the configured skeleton, then implement every domain hook:

   ```bash
   python <skill-dir>/create_oompa.py \
     --script-name <snake_case_name> --script-slug <kebab-case-slug> \
     --customer <customer> --organization-id <id> --version v1
   ```

   The generator uses [TEMPLATE.py](TEMPLATE.py), refuses overwrites, and validates identity fields. Use the next immutable friendly version (`v1`, `v2`, ...) when revising a published script.
5. Read [audit-contract.md](audit-contract.md) when implementing S3 paths, manifests, records, outcomes, or readback.
6. Validate, fix every error, and rerun until clean:

   ```bash
   python <skill-dir>/validate_oompa.py local_scripts/<customer>/<script>.py
   python -m py_compile local_scripts/<customer>/<script>.py
   ```

The template expects Django, `boto3`, and `botocore` from the Sytex production runner. The validator uses only Python's standard library.

## Operate a script

Read [production-runbook.md](production-runbook.md) completely before production access. Follow its sequence:

```text
plan → validate → checksum → preflight → dry-run/readback
     → approved canary/readback → fresh preflight
     → separately approved apply/reconciliation → idempotent dry-run
```

Before each approval request, report the exact version and checksums, organization and actor, selection and exclusions, outcome/reason/action totals, varied examples, review cases, artifact URIs, and verification query.

## Maintain this skill

Read [evaluations.md](evaluations.md) when changing the instructions, template, or validator. Run:

```bash
python <skill-dir>/test_validate_oompa.py
```
