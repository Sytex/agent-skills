# Production runbook

Use this runbook after the Oompa passes local validation. Commands are examples; resolve the namespace and pod from current production state instead of copying stale values.

## Contents

1. Prepare the reviewed source
2. Verify production access
3. Copy and verify the source
4. Preflight
5. Dry-run autonomously
6. Canary approval and apply
7. Full apply approval
8. Reconcile and close
9. Interruption and retry rules

## 1. Prepare the reviewed source

1. Confirm `SCRIPT_NAME`, `SCRIPT_VERSION`, customer, organization, selection predicate, exclusions, precedence policy, and intended effects.
2. Ensure the version is friendly and immutable (`v1`, `v2`, ...). Increment it after any functional change to a version already published to S3.
3. Validate and compile:

   ```bash
   python <skill-dir>/validate_oompa.py local_scripts/<customer>/<script>.py
   python -m py_compile local_scripts/<customer>/<script>.py
   sha256sum local_scripts/<customer>/<script>.py
   ```

The SHA-256 is an integrity check, not the user-facing version.

## 2. Verify production access

Resolve the current runner and verify access before copying anything:

```bash
kubectl auth can-i get pods -n <namespace>
kubectl get pods -n <namespace>
```

`Unauthorized`, an unexpected cluster/context, or denied access is a stop condition. Renew credentials and re-run the checks; do not work around authentication failures.

## 3. Copy and verify the source

Copy the reviewed file directly, avoiding wrappers that can alter the Python environment:

```bash
kubectl cp local_scripts/<customer>/<script>.py \
  <namespace>/<pod>:/tmp/oompa.py
kubectl exec -n <namespace> <pod> -- sha256sum /tmp/oompa.py
```

Require the runner checksum to equal the reviewed local checksum. The Oompa then publishes the exact file under `versions/vN/`, reads it back from S3, and checks the same checksum before processing.

## 4. Preflight

Preflight is read-only. Verify:

- the active organization and its stable ID;
- the accountable actor and required permissions;
- expected published/confirmed templates, configuration versions, or automation definitions;
- source and target uniqueness assumptions;
- dependencies and S3 access;
- exact selection query, stable ordering, total count, and explicit exclusions;
- the current distribution of likely outcomes and review reasons.

Do not silently broaden the query to make counts match an expectation. Explain drift and stop when it changes the approved risk profile.

## 5. Dry-run autonomously

Loading the source and calling `run()` are safe by default:

```python
exec(open("/tmp/oompa.py").read())
oompa.count()
oompa.run(max_items=10)
oompa.run()
```

Use a varied sample, not merely the first records. Include representative updates, no-ops, conflicts, missing data, and boundary cases when available.

Dry-run may only write immutable source and audit artifacts under the designated Oompa S3 prefix. It must not mutate business data, send notifications, execute automations, or trigger external integrations.

Read the uploaded objects independently. Reconcile JSONL/CSV rows, summary totals, outcome categories, action types, reasons, source version, and checksums. Printed totals are not sufficient evidence.

## 6. Canary approval and apply

Before canary, present the dry-run evidence, exact version, explicit object IDs, expected before/after values, and readback plan. Wait for explicit approval.

Example:

```python
oompa.run(
    dry_run=False,
    apply_kind="canary",
    item_ids=[<explicit-id>],
    confirm_organization_id=<organization-id>,
    actor_id=<actor-id>,
)
```

For each object:

1. start a transaction;
2. acquire an appropriate row lock;
3. re-read eligibility and approved preconditions;
4. apply only the classified actions;
5. commit;
6. query the after-state independently;
7. write and upload the audit record.

Stop if the result is unexpected. Canary approval does not authorize full apply.

## 7. Full apply approval

Run a fresh read-only preflight. Compare scope and distributions with the approved dry-run and canary. Explain any drift.

Present the exact full-apply scope and wait for a separate explicit approval:

```python
oompa.run(
    dry_run=False,
    apply_kind="apply",
    confirm_organization_id=<organization-id>,
    actor_id=<actor-id>,
)
```

Do not infer approval from phrases that only authorize investigation, dry-run, a canary, or a different version.

## 8. Reconcile and close

Independently reconcile:

- selected objects versus audited objects;
- proposed actions versus successful verified mutations;
- skipped/review/error totals and reasons;
- database after-state versus the expected state;
- source version/checksum versus the dry-run and approvals;
- S3 artifact existence, size, readability, and totals.

Finish with a full dry-run of the same version. A successful idempotency check should propose zero repeat mutations; remaining review cases must be stable and explained.

## Interruption and retry rules

- Append and upload audit records incrementally so progress survives process loss.
- If `kubectl`, the terminal, or the network times out, inspect pod state, running processes, and S3 artifacts before doing anything else.
- Do not start another run with the same scope until the previous run is proven finished or stopped.
- Resume only from independently verified completed objects and preserve the original `run_id` relationship in the new summary.
- A notification failure is non-fatal. A checksum, preflight, transaction, readback, or audit persistence failure is fatal for further writes.
