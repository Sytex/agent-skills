#!/usr/bin/env python3
"""Validate the static safety contract of an Oompa-Loompa source file."""

import argparse
import ast
import re
import sys
from pathlib import Path


REQUIRED_CONSTANTS = {
    "SCRIPT_NAME",
    "SCRIPT_SLUG",
    "SCRIPT_VERSION",
    "CUSTOMER_SLUG",
    "ORGANIZATION_ID",
    "S3_BUCKET",
    "S3_PREFIX",
}

REQUIRED_METHODS = {
    "count",
    "run",
    "validate_configuration",
    "preflight",
    "verify_version_sequence",
    "publish_and_verify_source",
    "get_items",
    "get_selection_metadata",
    "analyze_item",
    "lock_and_reload_item",
    "apply_item",
    "readback_item",
    "verify_after",
}

DOMAIN_HOOKS = {
    "get_active_organization_id",
    "validate_actor",
    "get_items",
    "get_selection_metadata",
    "get_item_identity",
    "analyze_item",
    "lock_and_reload_item",
    "apply_item",
    "readback_item",
    "verify_after",
}

REQUIRED_RUN_KEYWORDS = {
    "dry_run",
    "apply_kind",
    "max_items",
    "item_ids",
    "confirm_organization_id",
    "actor_id",
}

FORBIDDEN_SECRET_PATTERNS = (
    re.compile(r"https://(?:discord(?:app)?\.com)/api/webhooks/[^\s'\"]+"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"(?i)(?:api[_-]?key|secret|token|password)\s*=\s*['\"][^'\"]{8,}['\"]"),
)


def assigned_constants(tree):
    constants = {}
    for node in tree.body:
        if not isinstance(node, (ast.Assign, ast.AnnAssign)):
            continue
        targets = node.targets if isinstance(node, ast.Assign) else [node.target]
        value = node.value
        for target in targets:
            if isinstance(target, ast.Name):
                constants[target.id] = value
    return constants


def literal_value(node):
    try:
        return ast.literal_eval(node)
    except (ValueError, TypeError):
        return None


def find_oompa_class(tree):
    classes = [node for node in tree.body if isinstance(node, ast.ClassDef)]
    return next((node for node in classes if node.name == "OompaLoompa"), None)


def method_map(class_node):
    return {
        node.name: node
        for node in class_node.body
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
    }


def keyword_default(function, name):
    positional = list(function.args.args)
    positional_defaults = [None] * (len(positional) - len(function.args.defaults))
    positional_defaults.extend(function.args.defaults)
    for argument, default in zip(positional, positional_defaults):
        if argument.arg == name:
            return default
    for argument, default in zip(function.args.kwonlyargs, function.args.kw_defaults):
        if argument.arg == name:
            return default
    return None


def run_keyword_names(function):
    return {
        argument.arg
        for argument in (*function.args.args, *function.args.kwonlyargs)
        if argument.arg != "self"
    }


def called_method_names(function):
    names = set()
    for node in ast.walk(function):
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
            names.add(node.func.attr)
    return names


def method_call_lines(function):
    calls = {}
    for node in ast.walk(function):
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
            calls.setdefault(node.func.attr, node.lineno)
    return calls


def raises_not_implemented(function):
    for node in ast.walk(function):
        if not isinstance(node, ast.Raise) or node.exc is None:
            continue
        exception = node.exc.func if isinstance(node.exc, ast.Call) else node.exc
        if isinstance(exception, ast.Name) and exception.id == "NotImplementedError":
            return True
    return False


def unsafe_apply_examples(tree):
    violations = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call) or not isinstance(node.func, ast.Attribute):
            continue
        if node.func.attr != "run":
            continue
        keywords = {keyword.arg: keyword.value for keyword in node.keywords if keyword.arg}
        dry_run = literal_value(keywords.get("dry_run"))
        if dry_run is not False:
            continue
        required = {"apply_kind", "confirm_organization_id", "actor_id"}
        missing = required - keywords.keys()
        if missing:
            violations.append((node.lineno, sorted(missing)))
    return violations


def validate(path, *, allow_template_placeholders=False, source=None):
    errors = []
    if source is None:
        source = path.read_text(encoding="utf-8")
    try:
        tree = ast.parse(source, filename=str(path))
    except SyntaxError as exc:
        return [f"syntax error at line {exc.lineno}: {exc.msg}"]

    constants = assigned_constants(tree)
    missing_constants = sorted(REQUIRED_CONSTANTS - constants.keys())
    if missing_constants:
        errors.append(f"missing constants: {', '.join(missing_constants)}")

    version = literal_value(constants.get("SCRIPT_VERSION"))
    if not isinstance(version, str) or not re.fullmatch(r"v[1-9][0-9]*", version):
        errors.append("SCRIPT_VERSION must be a friendly version such as v1 or v2")

    if not allow_template_placeholders:
        if re.search(r"\bTODO\b", source):
            errors.append("unfinished TODO placeholder")
        for name in ("SCRIPT_NAME", "SCRIPT_SLUG", "CUSTOMER_SLUG"):
            value = literal_value(constants.get(name))
            if not isinstance(value, str) or not value or "REPLACE" in value:
                errors.append(f"{name} must be configured and contain no placeholder")
        for name in ("SCRIPT_SLUG", "CUSTOMER_SLUG"):
            value = literal_value(constants.get(name))
            if isinstance(value, str) and not re.fullmatch(
                r"[a-z0-9]+(?:-[a-z0-9]+)*", value
            ):
                errors.append(f"{name} must be a lowercase kebab-case slug")
        organization_id = literal_value(constants.get("ORGANIZATION_ID"))
        if not isinstance(organization_id, int) or organization_id <= 0:
            errors.append("ORGANIZATION_ID must be a positive integer")

    oompa_class = find_oompa_class(tree)
    if oompa_class is None:
        errors.append("missing OompaLoompa class")
    else:
        methods = method_map(oompa_class)
        missing_methods = sorted(REQUIRED_METHODS - methods.keys())
        if missing_methods:
            errors.append(f"missing methods: {', '.join(missing_methods)}")
        if not allow_template_placeholders:
            incomplete_hooks = sorted(
                name
                for name in DOMAIN_HOOKS
                if name in methods and raises_not_implemented(methods[name])
            )
            if incomplete_hooks:
                errors.append(
                    "unimplemented domain hooks: " + ", ".join(incomplete_hooks)
                )
        run = methods.get("run")
        if run:
            keyword_names = run_keyword_names(run)
            missing_keywords = sorted(REQUIRED_RUN_KEYWORDS - keyword_names)
            if missing_keywords:
                errors.append(f"run() missing safety parameters: {', '.join(missing_keywords)}")
            if "fail_fast" in keyword_names:
                errors.append("run() must not allow apply errors to bypass fail-fast behavior")
            default = keyword_default(run, "dry_run")
            if not isinstance(default, ast.Constant) or default.value is not True:
                errors.append("run() must default to dry_run=True")
            calls = called_method_names(run)
            for required_call in (
                "validate_configuration",
                "publish_and_verify_source",
                "preflight",
                "_start_artifacts",
                "_append_audit",
                "_readback_audits",
            ):
                if required_call not in calls:
                    errors.append(f"run() must call {required_call}()")
            call_lines = method_call_lines(run)
            if (
                "validate_configuration" in call_lines
                and "publish_and_verify_source" in call_lines
                and call_lines["validate_configuration"]
                > call_lines["publish_and_verify_source"]
            ):
                errors.append(
                    "run() must validate local configuration before publishing to S3"
                )

        preflight = methods.get("preflight")
        if preflight:
            preflight_source = ast.get_source_segment(source, preflight) or ""
            for token in ("confirm_organization_id", "actor_id", "canary", "apply"):
                if token not in preflight_source:
                    errors.append(f"preflight() must enforce {token}")

    if "customers/" not in source or "/oompas/" not in source:
        errors.append("S3_PREFIX must follow customers/<customer>/oompas/<script>")
    for segment in ("/versions/", "/runs/", "audit.jsonl", "audit.csv", "summary.json"):
        if segment not in source:
            errors.append(f"missing required S3/audit segment: {segment}")

    for pattern in FORBIDDEN_SECRET_PATTERNS:
        if pattern.search(source):
            errors.append(f"possible hardcoded secret matching {pattern.pattern!r}")

    for lineno, missing in unsafe_apply_examples(tree):
        errors.append(
            f"unsafe run(dry_run=False) example at line {lineno}; missing "
            + ", ".join(missing)
        )

    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+")
    parser.add_argument(
        "--allow-template-placeholders",
        action="store_true",
        help="Allow identity placeholders when validating the canonical template.",
    )
    args = parser.parse_args()

    failed = False
    for raw_path in args.paths:
        path = Path(raw_path)
        stdin_source = None
        if raw_path == "-":
            stdin_source = sys.stdin.read()
        elif not path.is_file():
            print(f"FAIL {path}: file not found")
            failed = True
            continue
        errors = validate(
            path,
            allow_template_placeholders=args.allow_template_placeholders,
            source=stdin_source,
        )
        if errors:
            failed = True
            print(f"FAIL {path}")
            for error in errors:
                print(f"  - {error}")
        else:
            print(f"OK   {path}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
