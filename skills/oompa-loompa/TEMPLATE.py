"""Audited production Oompa-Loompa template.

Copy this file to ``local_scripts/<customer>/``, replace every placeholder, and run the
skill validator before using it. Loading the file and ``oompa.run()`` are safe:
dry-run is the default and no notification integration is configured.
"""

import csv
import hashlib
import json
import os
import re
import tempfile
import traceback
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

import boto3
from botocore.exceptions import ClientError
from django.db import transaction


# === IDENTITY: replace every placeholder before use ===
SCRIPT_NAME = "REPLACE_script_name"
SCRIPT_SLUG = "REPLACE-script-slug"
SCRIPT_VERSION = "v1"
CUSTOMER_SLUG = "REPLACE-customer"
ORGANIZATION_ID = 0
S3_BUCKET = "sytex-data-transfer"
S3_PREFIX = f"customers/{CUSTOMER_SLUG}/oompas/{SCRIPT_SLUG}"

ALLOWED_OUTCOMES = {
    "would_update",
    "already_compliant",
    "manual_review",
    "would_update_partial",
    "updated",
    "updated_partial",
    "skipped",
    "error",
}

CSV_FIELDS = (
    "timestamp",
    "run_id",
    "mode",
    "script_name",
    "script_version",
    "organization_id",
    "actor_id",
    "object_id",
    "object_code",
    "outcome",
    "reasons",
    "before",
    "actions",
    "issues",
    "after",
    "mutations",
    "error",
    "traceback",
)


def utc_now():
    return datetime.now(timezone.utc)


def json_bytes(value):
    return json.dumps(
        value,
        ensure_ascii=False,
        default=str,
        sort_keys=True,
        indent=2,
    ).encode("utf-8")


def sha256_bytes(value):
    return hashlib.sha256(value).hexdigest()


class OompaLoompa:
    """Replace domain hooks while preserving the safety and audit lifecycle."""

    def __init__(
        self,
        *,
        instance_name="production",
        script_path="/tmp/oompa.py",
        s3_client=None,
    ):
        self.instance_name = instance_name
        self.script_path = Path(script_path)
        self.s3 = s3_client or boto3.client("s3")
        self.run_id = None
        self.mode = None
        self.run_prefix = None
        self.jsonl_path = None
        self.csv_path = None
        self.source_manifest = None
        self.started_at = None

    # === DOMAIN HOOKS: implement all of these ===
    def get_active_organization_id(self):
        """Return the active organization ID from current production state."""
        raise NotImplementedError

    def validate_actor(self, actor_id):
        """Return True only when the actor exists and is accountable for writes."""
        raise NotImplementedError

    def get_items(self, *, item_ids=None):
        """Return a QuerySet with deterministic ``order_by`` and exact scope."""
        raise NotImplementedError

    def get_selection_metadata(self):
        """Return eligibility predicate, exclusions, and source-of-truth policy."""
        raise NotImplementedError

    def get_item_identity(self, item):
        """Return ``{'object_id': ..., 'object_code': ...}`` for audit records."""
        raise NotImplementedError

    def analyze_item(self, item):
        """Return before/actions/issues/outcome/reasons without writing data.

        Expected shape::

            {
                "before": {...},
                "actions": [...],
                "issues": [...],
                "outcome": "would_update",
                "reasons": ["explicit_reason"],
            }
        """
        raise NotImplementedError

    def lock_and_reload_item(self, item):
        """Re-query and lock one item inside the current transaction."""
        raise NotImplementedError

    def apply_item(self, item, analysis, *, actor_id):
        """Apply only ``analysis['actions']`` and return mutation identifiers."""
        raise NotImplementedError

    def readback_item(self, item, analysis):
        """Independently query and return relevant after-state after commit."""
        raise NotImplementedError

    def verify_after(self, analysis, after):
        """Return ``(verified: bool, reasons: list[str])``."""
        raise NotImplementedError

    # === PREFLIGHT AND COUNT ===
    def validate_configuration(self):
        if ORGANIZATION_ID <= 0:
            raise RuntimeError("template_identity_not_configured")
        if any("REPLACE" in value for value in (SCRIPT_NAME, SCRIPT_SLUG, CUSTOMER_SLUG)):
            raise RuntimeError("template_identity_not_configured")
        if not re.fullmatch(r"v[1-9][0-9]*", SCRIPT_VERSION):
            raise RuntimeError("script_version_must_be_v1_v2_etc")
        if not self.script_path.is_file():
            raise RuntimeError(f"script_source_not_found:{self.script_path}")

    def count(self, *, item_ids=None):
        self.validate_configuration()
        if self.get_active_organization_id() != ORGANIZATION_ID:
            raise RuntimeError("active_organization_mismatch")
        return self.get_items(item_ids=item_ids).count()

    def preflight(
        self,
        *,
        dry_run,
        apply_kind,
        item_ids,
        max_items,
        confirm_organization_id,
        actor_id,
    ):
        """Run read-only safety checks before selecting business objects."""
        self.validate_configuration()
        if self.get_active_organization_id() != ORGANIZATION_ID:
            raise RuntimeError("active_organization_mismatch")

        if dry_run:
            if apply_kind is not None:
                raise RuntimeError("apply_kind_is_only_valid_for_writes")
            return

        if apply_kind not in {"canary", "apply"}:
            raise RuntimeError("writes_require_apply_kind_canary_or_apply")
        if confirm_organization_id != ORGANIZATION_ID:
            raise RuntimeError("writes_require_exact_organization_confirmation")
        if not actor_id or not self.validate_actor(actor_id):
            raise RuntimeError("writes_require_valid_actor")
        if apply_kind == "canary" and not item_ids:
            raise RuntimeError("canary_requires_explicit_item_ids")
        if apply_kind == "apply" and item_ids:
            raise RuntimeError("full_apply_must_not_use_canary_item_ids")
        if apply_kind == "apply" and max_items is not None:
            raise RuntimeError("full_apply_must_not_use_sample_limit")

        # Extend this preflight with expected template/configuration versions,
        # permissions, dependencies, uniqueness assumptions, and scope invariants.

    # === IMMUTABLE SOURCE PUBLICATION ===
    @property
    def source_key(self):
        return f"{S3_PREFIX}/versions/{SCRIPT_VERSION}/script.py"

    @property
    def manifest_key(self):
        return f"{S3_PREFIX}/versions/{SCRIPT_VERSION}/manifest.json"

    def _read_s3_bytes(self, key):
        return self.s3.get_object(Bucket=S3_BUCKET, Key=key)["Body"].read()

    def _head_or_none(self, key):
        try:
            return self.s3.head_object(Bucket=S3_BUCKET, Key=key)
        except ClientError as exc:
            if exc.response.get("Error", {}).get("Code") in {
                "404",
                "NoSuchKey",
                "NotFound",
            }:
                return None
            raise

    def _put_immutable(self, key, body, *, content_type):
        existing = self._head_or_none(key)
        if existing is not None:
            existing_body = self._read_s3_bytes(key)
            if existing_body != body:
                raise RuntimeError(f"immutable_s3_version_collision:{key}")
            return existing.get("VersionId")

        try:
            response = self.s3.put_object(
                Bucket=S3_BUCKET,
                Key=key,
                Body=body,
                ContentType=content_type,
                IfNoneMatch="*",
            )
        except ClientError as exc:
            if exc.response.get("ResponseMetadata", {}).get("HTTPStatusCode") != 412:
                raise
            if self._read_s3_bytes(key) != body:
                raise RuntimeError(f"immutable_s3_version_collision:{key}") from exc
            return self._head_or_none(key).get("VersionId")
        return response.get("VersionId")

    def verify_version_sequence(self):
        version_number = int(SCRIPT_VERSION[1:])
        if version_number == 1:
            return
        previous_key = (
            f"{S3_PREFIX}/versions/v{version_number - 1}/script.py"
        )
        if self._head_or_none(previous_key) is None:
            raise RuntimeError(
                f"previous_friendly_version_missing:{previous_key}"
            )

    def publish_and_verify_source(self):
        self.verify_version_sequence()
        source = self.script_path.read_bytes()
        source_sha256 = sha256_bytes(source)
        version_id = self._put_immutable(
            self.source_key,
            source,
            content_type="text/x-python",
        )
        source_uri = f"s3://{S3_BUCKET}/{self.source_key}"
        new_manifest = {
            "script_name": SCRIPT_NAME,
            "script_slug": SCRIPT_SLUG,
            "script_version": SCRIPT_VERSION,
            "customer": CUSTOMER_SLUG,
            "organization_id": ORGANIZATION_ID,
            "source_uri": source_uri,
            "source_sha256": source_sha256,
            "source_size": len(source),
            "published_at": utc_now().isoformat(),
            "git_commit": os.environ.get("GIT_COMMIT") or None,
            "s3_version_id": version_id,
        }
        existing_manifest = self._head_or_none(self.manifest_key)
        if existing_manifest is None:
            self._put_immutable(
                self.manifest_key,
                json_bytes(new_manifest),
                content_type="application/json",
            )
            manifest = new_manifest
        else:
            manifest = json.loads(self._read_s3_bytes(self.manifest_key))
            if manifest.get("source_sha256") != source_sha256:
                raise RuntimeError(
                    f"immutable_s3_version_collision:{self.manifest_key}"
                )
        readback = self._read_s3_bytes(self.source_key)
        if sha256_bytes(readback) != source_sha256:
            raise RuntimeError("s3_source_checksum_readback_mismatch")
        self.source_manifest = manifest
        return manifest

    # === RUN ARTIFACTS ===
    def _start_artifacts(self, *, mode, selection):
        now = utc_now()
        self.started_at = now.isoformat()
        timestamp = now.strftime("%Y%m%dT%H%M%SZ")
        self.mode = mode
        self.run_id = f"{SCRIPT_SLUG}-{mode}-{timestamp}-{uuid4().hex[:8]}"
        self.run_prefix = (
            f"{S3_PREFIX}/runs/{mode}/{now:%Y/%m/%d}/{self.run_id}"
        )
        self.jsonl_path = Path(tempfile.gettempdir()) / f"{self.run_id}.jsonl"
        self.csv_path = Path(tempfile.gettempdir()) / f"{self.run_id}.csv"
        self.jsonl_path.touch(exist_ok=False)
        with self.csv_path.open("x", encoding="utf-8", newline="") as csv_file:
            csv.DictWriter(csv_file, fieldnames=CSV_FIELDS).writeheader()
            csv_file.flush()
            os.fsync(csv_file.fileno())
        self._upload_audits()
        self._write_summary(
            status="running",
            selection=selection,
            counters={},
            error=None,
        )

    def _upload_audits(self):
        self.s3.upload_file(
            str(self.jsonl_path),
            S3_BUCKET,
            f"{self.run_prefix}/audit.jsonl",
        )
        self.s3.upload_file(
            str(self.csv_path),
            S3_BUCKET,
            f"{self.run_prefix}/audit.csv",
        )

    @staticmethod
    def _csv_value(value):
        if isinstance(value, (dict, list, tuple, set)):
            return json.dumps(value, ensure_ascii=False, default=str, sort_keys=True)
        return value

    def _append_audit(self, record):
        record = {
            "timestamp": utc_now().isoformat(),
            "run_id": self.run_id,
            "mode": self.mode,
            "script_name": SCRIPT_NAME,
            "script_version": SCRIPT_VERSION,
            "organization_id": ORGANIZATION_ID,
            **record,
        }
        if record["outcome"] not in ALLOWED_OUTCOMES:
            raise RuntimeError(f"invalid_outcome:{record['outcome']}")
        with self.jsonl_path.open("a", encoding="utf-8") as jsonl_file:
            jsonl_file.write(json.dumps(record, ensure_ascii=False, default=str) + "\n")
            jsonl_file.flush()
            os.fsync(jsonl_file.fileno())
        with self.csv_path.open("a", encoding="utf-8", newline="") as csv_file:
            csv.DictWriter(csv_file, fieldnames=CSV_FIELDS).writerow(
                {
                    field: self._csv_value(record.get(field))
                    for field in CSV_FIELDS
                }
            )
            csv_file.flush()
            os.fsync(csv_file.fileno())
        self._upload_audits()

    def _write_summary(self, *, status, selection, counters, error, readback=None):
        normalized_counters = {
            category: dict(values) for category, values in counters.items()
        }
        summary = {
            "run_id": self.run_id,
            "mode": self.mode,
            "status": status,
            "started_at": self.started_at,
            "completed_at": utc_now().isoformat() if status != "running" else None,
            "updated_at": utc_now().isoformat(),
            "instance": self.instance_name,
            "organization_id": ORGANIZATION_ID,
            "actor_id": selection.get("actor_id"),
            "selection": selection,
            "script": self.source_manifest,
            "counters": normalized_counters,
            "error": error,
            "readback": readback,
            "artifacts": {
                "jsonl_uri": f"s3://{S3_BUCKET}/{self.run_prefix}/audit.jsonl",
                "csv_uri": f"s3://{S3_BUCKET}/{self.run_prefix}/audit.csv",
                "summary_uri": f"s3://{S3_BUCKET}/{self.run_prefix}/summary.json",
            },
        }
        self.s3.put_object(
            Bucket=S3_BUCKET,
            Key=f"{self.run_prefix}/summary.json",
            Body=json_bytes(summary),
            ContentType="application/json",
        )
        return summary

    def _readback_audits(self):
        body = self._read_s3_bytes(f"{self.run_prefix}/audit.jsonl")
        records = [json.loads(line) for line in body.decode("utf-8").splitlines()]
        if any(record.get("run_id") != self.run_id for record in records):
            raise RuntimeError("audit_readback_run_id_mismatch")
        outcomes = Counter()
        reasons = Counter()
        actions = Counter()
        for record in records:
            outcomes[record["outcome"]] += 1
            reasons.update(record.get("reasons") or [])
            for action in record.get("actions") or []:
                if isinstance(action, dict):
                    action_name = action.get("type") or action.get("action") or "unknown"
                else:
                    action_name = str(action)
                actions[action_name] += 1
        return {
            "rows": len(records),
            "counters": {
                "outcomes": dict(outcomes),
                "reasons": dict(reasons),
                "actions": dict(actions),
            },
            "jsonl_sha256": sha256_bytes(body),
        }

    @staticmethod
    def _increment_counters(counters, record):
        counters["outcomes"][record["outcome"]] += 1
        counters["reasons"].update(record.get("reasons") or [])
        for action in record.get("actions") or []:
            if isinstance(action, dict):
                action_name = action.get("type") or action.get("action") or "unknown"
            else:
                action_name = str(action)
            counters["actions"][action_name] += 1

    # === EXECUTION ===
    @staticmethod
    def _validate_analysis(analysis):
        if not isinstance(analysis, dict):
            raise RuntimeError("analysis_must_be_a_dict")
        for field in ("before", "actions", "issues", "outcome", "reasons"):
            if field not in analysis:
                raise RuntimeError(f"analysis_missing_field:{field}")
        for field in ("actions", "issues", "reasons"):
            if not isinstance(analysis[field], list):
                raise RuntimeError(f"analysis_{field}_must_be_a_list")
        if any(not isinstance(reason, str) for reason in analysis["reasons"]):
            raise RuntimeError("analysis_reasons_must_be_strings")
        if analysis["outcome"] not in ALLOWED_OUTCOMES:
            raise RuntimeError(f"invalid_analysis_outcome:{analysis['outcome']}")
        if analysis["actions"] and analysis["outcome"] not in {
            "would_update",
            "would_update_partial",
        }:
            raise RuntimeError("actions_require_would_update_outcome")
        return analysis

    def _apply_one(self, item, initial_analysis, *, actor_id):
        with transaction.atomic():
            locked_item = self.lock_and_reload_item(item)
            current_analysis = self._validate_analysis(self.analyze_item(locked_item))
            initial_fingerprint = json.dumps(
                initial_analysis,
                ensure_ascii=False,
                default=str,
                sort_keys=True,
            )
            current_fingerprint = json.dumps(
                current_analysis,
                ensure_ascii=False,
                default=str,
                sort_keys=True,
            )
            if current_fingerprint != initial_fingerprint:
                raise RuntimeError("write_preconditions_drifted")
            mutations = self.apply_item(
                locked_item,
                current_analysis,
                actor_id=actor_id,
            )

        after = self.readback_item(locked_item, current_analysis)
        verified, reasons = self.verify_after(current_analysis, after)
        if not verified:
            raise RuntimeError(f"independent_readback_failed:{reasons}")
        outcome = "updated_partial" if current_analysis.get("issues") else "updated"
        combined_reasons = list(current_analysis.get("reasons", [])) + list(reasons)
        return outcome, combined_reasons, mutations, after

    def run(
        self,
        *,
        dry_run=True,
        apply_kind=None,
        max_items=None,
        item_ids=None,
        confirm_organization_id=None,
        actor_id=None,
        parent_run_id=None,
        approved_run_ids=None,
    ):
        """Evaluate or apply one exact scope; dry-run is always the default."""
        self.validate_configuration()
        source_manifest = self.publish_and_verify_source()
        self.preflight(
            dry_run=dry_run,
            apply_kind=apply_kind,
            item_ids=item_ids,
            max_items=max_items,
            confirm_organization_id=confirm_organization_id,
            actor_id=actor_id,
        )
        mode = "dry-run" if dry_run else apply_kind
        selection = {
            **self.get_selection_metadata(),
            "item_ids": list(item_ids) if item_ids else None,
            "max_items": max_items,
            "actor_id": actor_id,
            "parent_run_id": parent_run_id,
            "approved_run_ids": list(approved_run_ids) if approved_run_ids else [],
        }
        items = self.get_items(item_ids=item_ids)
        if max_items is not None:
            items = items[:max_items]
        selected_count = len(items) if isinstance(items, list) else items.count()
        selection["selected_count"] = selected_count
        self.source_manifest = source_manifest
        self._start_artifacts(mode=mode, selection=selection)

        counters = {
            "outcomes": Counter(),
            "reasons": Counter(),
            "actions": Counter(),
        }
        terminal_error = None
        try:
            for position, item in enumerate(items.iterator(), start=1):
                identity = self.get_item_identity(item)
                analysis = self._validate_analysis(self.analyze_item(item))
                base_record = {
                    "actor_id": actor_id,
                    **identity,
                    "before": analysis.get("before"),
                    "actions": analysis.get("actions", []),
                    "issues": analysis.get("issues", []),
                    "reasons": analysis.get("reasons", []),
                    "after": None,
                    "mutations": None,
                    "error": None,
                    "traceback": None,
                }
                try:
                    if dry_run or not analysis.get("actions"):
                        outcome = analysis["outcome"]
                        record = {**base_record, "outcome": outcome}
                    else:
                        outcome, reasons, mutations, after = self._apply_one(
                            item,
                            analysis,
                            actor_id=actor_id,
                        )
                        record = {
                            **base_record,
                            "outcome": outcome,
                            "reasons": reasons,
                            "mutations": mutations,
                            "after": after,
                        }
                    self._append_audit(record)
                    self._increment_counters(counters, record)
                except Exception as exc:
                    outcome = "error"
                    error_record = {
                        **base_record,
                        "outcome": outcome,
                        "reasons": [
                            "processing_or_verification_failed"
                            if dry_run
                            else "write_state_uncertain"
                        ],
                        "error": f"{type(exc).__name__}: {exc}",
                        "traceback": traceback.format_exc(),
                    }
                    self._append_audit(error_record)
                    self._increment_counters(counters, error_record)
                    if not dry_run:
                        raise

                if position % 100 == 0 or position == selected_count:
                    print(
                        f"[{mode}] {position}/{selected_count} "
                        f"outcomes={dict(counters['outcomes'])}"
                    )
        except Exception as exc:
            terminal_error = f"{type(exc).__name__}: {exc}"

        completion = "completed"
        if terminal_error:
            completion = "failed" if dry_run else "uncertain"
        readback = self._readback_audits()
        expected_counters = {
            category: dict(values) for category, values in counters.items()
        }
        if (
            readback["rows"] != sum(counters["outcomes"].values())
            or readback["counters"] != expected_counters
        ):
            completion = "uncertain"
            terminal_error = terminal_error or "audit_readback_count_mismatch"
        summary = self._write_summary(
            status=completion,
            selection=selection,
            counters=counters,
            error=terminal_error,
            readback=readback,
        )
        print(json.dumps(summary, ensure_ascii=False, default=str, indent=2))
        if completion != "completed":
            raise RuntimeError(f"oompa_run_not_complete:{completion}:{terminal_error}")
        return summary


# === SAFE ENTRY POINT ===
# When executing a different runner path, pass it explicitly to OompaLoompa.
oompa = OompaLoompa(script_path="/tmp/oompa.py")
print(
    f"""
=== OOMPA-LOOMPA: {SCRIPT_NAME} {SCRIPT_VERSION} ===

Safe inspection and dry-run (no business-data writes):
  oompa.count()
  oompa.run(max_items=10)
  oompa.run()

Canary (only after explicit approval):
  oompa.run(
      dry_run=False,
      apply_kind="canary",
      item_ids=[<explicit-id>],
      confirm_organization_id={ORGANIZATION_ID},
      actor_id=<actor-id>,
  )

Full apply (requires a new explicit approval after canary readback):
  oompa.run(
      dry_run=False,
      apply_kind="apply",
      confirm_organization_id={ORGANIZATION_ID},
      actor_id=<actor-id>,
  )

Copy and verify:
  kubectl cp local_scripts/<customer>/<script>.py <namespace>/<pod>:/tmp/oompa.py
  sha256sum local_scripts/<customer>/<script>.py
  kubectl exec -n <namespace> <pod> -- sha256sum /tmp/oompa.py

Load in Django shell_plus:
  exec(open("/tmp/oompa.py").read())
"""
)
