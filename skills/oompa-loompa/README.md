# Oompa-Loompa

Creates and operates audited one-off Sytex production scripts for migrations, imports, backfills, cleanups, and reconciliations.

The package includes:

- a safe-by-default, self-auditing Django `shell_plus` template;
- a generator that configures identity and refuses overwrites;
- a static contract validator and regression tests;
- production approval, S3 layout, audit, readback, and recovery guidance.

Generated scripts default to dry-run. Mutating canaries and full applies require separate explicit approvals.

Run the package tests from this repository with:

```bash
python skills/oompa-loompa/test_validate_oompa.py
```
