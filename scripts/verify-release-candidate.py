#!/usr/bin/env python3
"""Fail-closed comparison of release archives to committed-input inventory scope."""

import argparse
import hashlib
import json
import tarfile
from pathlib import Path, PurePosixPath


def normalized(name: str) -> str:
    name = name.removeprefix("./")
    return name.rstrip("/")


def inspect_archive(path: Path) -> list[dict]:
    if not path.is_file():
        raise ValueError(f"required release candidate artifact is absent: {path}")
    entries = []
    with tarfile.open(path, "r:*") as archive:
        for member in archive.getmembers():
            name = normalized(member.name)
            pure = PurePosixPath(name)
            if not name or member.isdir():
                continue
            if pure.is_absolute() or ".." in pure.parts or member.issym() or member.islnk():
                raise ValueError(f"unsafe archive member in {path.name}: {member.name}")
            if not member.isfile():
                raise ValueError(f"unsupported archive member in {path.name}: {member.name}")
            stream = archive.extractfile(member)
            if stream is None:
                raise ValueError(f"could not read archive member in {path.name}: {member.name}")
            digest = hashlib.sha256()
            size = 0
            while chunk := stream.read(1024 * 1024):
                digest.update(chunk)
                size += len(chunk)
            entries.append({"path": name, "sha256": digest.hexdigest(), "size": size})
    entries.sort(key=lambda item: item["path"])
    if not entries:
        raise ValueError(f"release candidate artifact is empty: {path}")
    if len({item['path'] for item in entries}) != len(entries):
        raise ValueError(f"release candidate contains duplicate paths: {path}")
    return entries


def web_candidate_path(inventory_path: str) -> str:
    """Map tracked web and pubspec assets to their Flutter web archive member."""
    if inventory_path.startswith("web/"):
        return inventory_path[len("web/"):]
    if inventory_path.startswith("assets/"):
        return f"assets/{inventory_path}"
    raise ValueError(f"unsupported web candidate inventory path: {inventory_path}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", type=Path, required=True)
    parser.add_argument("--web-archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        inventory = json.loads(args.inventory.read_text(encoding="utf-8"))
        web = inspect_archive(args.web_archive)
        web_by_path = {item["path"]: item for item in web}
        expected = [item for item in inventory["assets"]
                    if item["distribution"]["current_candidate"] == "expected-in-web-archive"]
        comparisons = []
        for item in expected:
            candidate_path = web_candidate_path(item["path"])
            actual = web_by_path.get(candidate_path)
            method = item["distribution"].get("verification", "source-sha256")
            matched = bool(actual) and (method == "presence" or actual["sha256"] == item["sha256"])
            comparisons.append({"inventory_path": item["path"], "candidate_path": candidate_path,
                                "verification": method,
                                "expected_sha256": item["sha256"],
                                "actual_sha256": actual["sha256"] if actual else None,
                                "status": "matched" if matched else "mismatch-or-absent"})
        failures = [item for item in comparisons if item["status"] != "matched"]
        if failures:
            raise ValueError("web candidate does not match inventory assets: " +
                             ", ".join(item["inventory_path"] for item in failures))
        report = {
            "schema_version": 1,
            "source_revision": inventory["source_revision"],
            "approval": "NOT APPROVED - engineering artifact comparison only",
            "artifacts": [
                {"name": args.web_archive.name, "kind": "flutter-web-tar", "contents": web,
                 "inventory_asset_comparisons": comparisons,
                 "scope_note": "Tracked web/pubspec assets are hash-compared; generated compiled files are recorded but have no source-asset identity."},
            ],
            "limitations": "Native applications are absent from this workflow and are not verified by this report.",
        }
        args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (OSError, KeyError, json.JSONDecodeError, tarfile.TarError, ValueError) as exc:
        print(f"Release candidate verification failed: {exc}", file=__import__('sys').stderr)
        return 1
    print(f"Verified candidate contents against available inventory scope: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
