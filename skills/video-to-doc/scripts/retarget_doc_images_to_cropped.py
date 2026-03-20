#!/usr/bin/env python3
"""
Retarget Markdown image links from /screenshots/ to /screenshots-cropped/.

Usage:
  python scripts/retarget_doc_images_to_cropped.py --docs docs/a.md docs/b.md
"""

from __future__ import annotations

import argparse
from pathlib import Path


def retarget_text(text: str) -> tuple[str, int]:
    old = "/screenshots/"
    new = "/screenshots-cropped/"
    count = text.count(old)
    return text.replace(old, new), count


def main() -> None:
    parser = argparse.ArgumentParser(description="Retarget markdown image paths to screenshots-cropped.")
    parser.add_argument("--docs", nargs="+", required=True, help="Markdown files to rewrite in place.")
    args = parser.parse_args()

    total = 0
    touched = 0
    for doc in args.docs:
        p = Path(doc)
        if not p.exists():
            raise SystemExit(f"Missing file: {p}")
        text = p.read_text(encoding="utf-8")
        updated, count = retarget_text(text)
        if count > 0:
            p.write_text(updated, encoding="utf-8")
            touched += 1
            total += count

    print(f"updated_files={touched} replaced_links={total}")


if __name__ == "__main__":
    main()
