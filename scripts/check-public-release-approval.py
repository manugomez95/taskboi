#!/usr/bin/env python3
"""Validate a complete public-release approval tied to an exact commit SHA."""

import argparse
import re
from pathlib import Path

FIELDS = (
    "Approval status",
    "Named human/legal reviewer",
    "Review date (YYYY-MM-DD)",
    "Source revision",
    "Scoped distribution channels",
    "Notices decision",
    "License texts decision",
    "Source-offer decision",
    "Asset provenance attestations",
    "Vulnerability disposition",
)
PLACEHOLDERS = {"", "TBD", "UNDECIDED", "NOASSERTION", "NOT APPROVED"}


def fail(message: str) -> int:
    print(f"NOT APPROVED: {message}")
    return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("record", type=Path)
    parser.add_argument("--expected-revision", required=True)
    args = parser.parse_args()

    if not re.fullmatch(r"[0-9a-f]{40}", args.expected_revision):
        return fail("expected revision must be an exact lowercase 40-character commit SHA")
    try:
        text = args.record.read_text(encoding="utf-8")
    except OSError:
        return fail("approval record is missing or unreadable")

    values = {}
    for line in text.splitlines():
        match = re.fullmatch(r"- ([^:]+):\s*(.*)", line)
        if match:
            values[match.group(1)] = match.group(2).strip()
    missing = [field for field in FIELDS if field not in values]
    if missing:
        return fail("required fields are missing: " + ", ".join(missing))
    unresolved = [field for field in FIELDS if values[field].upper() in PLACEHOLDERS]
    if unresolved:
        return fail("record contains unresolved fields: " + ", ".join(unresolved))
    if values["Approval status"] != "APPROVED":
        return fail("approval status is not APPROVED")
    if values["Source revision"] != args.expected_revision:
        return fail("source revision does not match the exact expected SHA")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", values["Review date (YYYY-MM-DD)"]):
        return fail("review date must use YYYY-MM-DD")
    print(f"APPROVED: public release record matches {args.expected_revision}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
