# Audit and S3 contract

Every dry-run, canary, and apply must preserve enough evidence to identify the exact source, reconstruct decisions per object, and independently verify the outcome.

## Contents

- Canonical S3 layout
- Version manifest
- Run identifiers and summary
- Per-object audit record
- Outcome semantics
- Persistence and readback

## Canonical S3 layout

```text
s3://sytex-data-transfer/
└── customers/{customer}/
    └── oompas/{script_slug}/
        ├── versions/
        │   ├── v1/
        │   │   ├── script.py
        │   │   └── manifest.json
        │   └── v2/
        │       ├── script.py
        │       └── manifest.json
        └── runs/
            ├── dry-run/{YYYY}/{MM}/{DD}/{run_id}/
            │   ├── audit.jsonl
            │   ├── audit.csv
            │   └── summary.json
            ├── canary/{YYYY}/{MM}/{DD}/{run_id}/
            │   └── ...
            └── apply/{YYYY}/{MM}/{DD}/{run_id}/
                └── ...
```

Rules:

- Keep customer data below `customers/{customer}/`; never place files directly in the customer root.
- Use one stable lowercase `script_slug` for the lifetime of the Oompa.
- Use friendly sequential versions (`v1`, `v2`, ...). Never overwrite a published version.
- Reuse the same version across multiple executions when its source is unchanged.
- Increment the version after every functional source change. Do not use names such as `final`, `final_v2`, or `new_final`.
- Separate run artifacts by mode and UTC date. Keep all artifacts for one execution in its `run_id` directory.
- Do not mix Oompa source/audits with imports, exports, attachments, or unrelated temporary files.
- Never delete prior execution evidence as part of an Oompa run. Retention/lifecycle policy is an independent infrastructure decision.

## Version manifest

`versions/vN/manifest.json` must include:

- `script_name`, `script_slug`, and `script_version`;
- customer and organization ID;
- source S3 URI;
- source SHA-256 and byte size;
- UTC publication time;
- Git commit when available;
- S3 `VersionId` when bucket versioning provides one.

The SHA-256 verifies identity but is not the friendly version name. If `vN` already exists with a different checksum, stop and publish the changed source as the next version. After publication, read the object body or metadata back from S3 and verify it.

## Run identifiers and summary

Use a unique stable `run_id` containing script, mode, UTC timestamp, and a short random suffix. `summary.json` must include:

- `run_id`, mode, start/end timestamps, instance, organization, and actor;
- exact selection parameters, exclusions, explicit IDs, and limits;
- script version, source URI, SHA-256, and S3 `VersionId` when available;
- total selected/audited plus counters by outcome, reason, and action type;
- JSONL and CSV URIs;
- completion state (`completed`, `failed`, or `uncertain`) and failure details;
- parent run or approved dry-run/canary IDs when applicable.

Write the final summary only after independently reconciling the uploaded artifacts. A partial summary may be uploaded during execution, but it must be marked `running` or `uncertain`.

## Per-object audit record

Append one JSONL row per evaluated object. CSV is a flattened human-review projection of the same records. Each record must include:

- timestamp, run ID, mode, script version, organization, and actor;
- stable object identifiers and useful human-readable code/name;
- relevant source and target identifiers;
- eligibility inputs and configuration/template versions;
- `before`, proposed or applied `actions`, `issues`, and independently queried `after`;
- normalized `outcome` and one or more explicit `reasons`;
- created/updated object IDs when applicable;
- error type/message and traceback for failures, with secrets removed.

Do not log full tokens, cookies, credentials, webhooks, unnecessary personal data, or file contents. Prefer stable IDs and narrowly relevant state.

## Outcome semantics

Use consistent categories:

- `would_update`: dry-run found safe actions.
- `already_compliant`: no action is required.
- `manual_review`: ambiguity, missing information, conflict, or unsupported case prevents an automatic action.
- `would_update_partial`: dry-run found safe isolated actions plus remaining review issues.
- `updated`: apply completed and after-state independently matches expectation.
- `updated_partial`: safe isolated actions were verified but review issues remain.
- `skipped`: explicitly out of scope or no longer eligible, with a reason.
- `error`: processing or verification failed.

Review is not synonymous with corruption. Record all applicable reasons so reviewers can distinguish a real defect, missing source content, protected target data, and a conservative false positive.

## Persistence and readback

- Create empty JSONL/CSV artifacts and upload them at run start.
- Flush and fsync locally after every appended record or small bounded batch.
- Upload incrementally; do not wait until process completion.
- Read artifacts back using a separate S3 request and validate their size, parseability, run ID, row count, and counters.
- Treat audit upload/readback failure as a stop condition before further business writes.
- Printed progress and in-process counters are operational hints, not independent evidence.
