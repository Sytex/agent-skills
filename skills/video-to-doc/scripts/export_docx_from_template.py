#!/usr/bin/env python3
"""
Export one or more Markdown files to DOCX using a reference template.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


def export_one(md_file: Path, template: Path, resource_path: str) -> Path:
    out = md_file.with_suffix(".docx")
    cmd = [
        "pandoc",
        str(md_file),
        "-f",
        "gfm",
        "-t",
        "docx",
        f"--reference-doc={template}",
        f"--resource-path={resource_path}",
        "-o",
        str(out),
    ]
    subprocess.run(cmd, check=True)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Export markdown files to docx using a template.")
    parser.add_argument("--template", required=True, help="Reference DOCX template path.")
    parser.add_argument("--markdown", nargs="+", required=True, help="Markdown files to export.")
    parser.add_argument(
        "--resource-path",
        default=".:docs:artifacts",
        help="Pandoc resource path for images.",
    )
    args = parser.parse_args()

    if shutil.which("pandoc") is None:
        raise SystemExit("pandoc not found in PATH")

    template = Path(args.template)
    if not template.exists():
        raise SystemExit(f"Template not found: {template}")

    for md in args.markdown:
        md_file = Path(md)
        if not md_file.exists():
            raise SystemExit(f"Markdown not found: {md_file}")
        out = export_one(md_file, template, args.resource_path)
        print(f"exported: {out}")


if __name__ == "__main__":
    main()
