#!/usr/bin/env python3
"""Create a configured Oompa source from the canonical template."""

import argparse
import re
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parent
TEMPLATE_PATH = SKILL_DIR / "TEMPLATE.py"


def require_match(name, value, pattern):
    if not re.fullmatch(pattern, value):
        raise ValueError(f"invalid {name}: {value!r}")


def render(*, script_name, script_slug, version, customer, organization_id):
    require_match("script_name", script_name, r"[a-z][a-z0-9_]*")
    require_match("script_slug", script_slug, r"[a-z0-9]+(?:-[a-z0-9]+)*")
    require_match("customer", customer, r"[a-z0-9]+(?:-[a-z0-9]+)*")
    require_match("version", version, r"v[1-9][0-9]*")
    if organization_id <= 0:
        raise ValueError("organization_id must be positive")

    source = TEMPLATE_PATH.read_text(encoding="utf-8")
    replacements = {
        'SCRIPT_NAME = "REPLACE_script_name"': f'SCRIPT_NAME = "{script_name}"',
        'SCRIPT_SLUG = "REPLACE-script-slug"': f'SCRIPT_SLUG = "{script_slug}"',
        'CUSTOMER_SLUG = "REPLACE-customer"': f'CUSTOMER_SLUG = "{customer}"',
        "ORGANIZATION_ID = 0": f"ORGANIZATION_ID = {organization_id}",
        'SCRIPT_VERSION = "v1"': f'SCRIPT_VERSION = "{version}"',
    }
    for old, new in replacements.items():
        if source.count(old) != 1:
            raise RuntimeError(f"template marker missing or duplicated: {old}")
        source = source.replace(old, new, 1)
    return source


def create(*, output_root, **identity):
    target = output_root / identity["customer"] / f"{identity['script_name']}.py"
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("x", encoding="utf-8") as output:
        output.write(render(**identity))
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--script-name", required=True)
    parser.add_argument("--script-slug", required=True)
    parser.add_argument("--version", default="v1")
    parser.add_argument("--customer", required=True)
    parser.add_argument("--organization-id", required=True, type=int)
    parser.add_argument("--output-root", type=Path, default=Path("local_scripts"))
    args = parser.parse_args()

    target = create(
        output_root=args.output_root,
        script_name=args.script_name,
        script_slug=args.script_slug,
        version=args.version,
        customer=args.customer,
        organization_id=args.organization_id,
    )
    print(target)


if __name__ == "__main__":
    main()
