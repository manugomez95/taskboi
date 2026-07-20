#!/usr/bin/env python3
"""Fail-closed comparison of release archives to committed-input inventory scope."""

import argparse
import hashlib
import json
import tarfile
from pathlib import Path, PurePosixPath


def normalized(name: str, npm: bool) -> str:
    name = name.removeprefix("./")
    if npm and name.startswith("package/"):
        name = name[len("package/"):]
    return name.rstrip("/")


def inspect_archive(path: Path, npm: bool) -> list[dict]:
    if not path.is_file():
        raise ValueError(f"required release candidate artifact is absent: {path}")
    entries = []
    with tarfile.open(path, "r:*") as archive:
        for member in archive.getmembers():
            name = normalized(member.name, npm)
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


def inspect_npm_source(path: Path) -> list[dict]:
    """Build the exact package member expectation from the prepared source tree."""
    package_json_path = path / "package.json"
    if not package_json_path.is_file():
        raise ValueError(f"npm source is missing package.json: {path}")
    package = json.loads(package_json_path.read_text(encoding="utf-8"))
    declared = package.get("files")
    if not isinstance(declared, list) or not declared or not all(
            isinstance(item, str) and item and not PurePosixPath(item).is_absolute()
            and ".." not in PurePosixPath(item).parts for item in declared):
        raise ValueError("npm package.json files must be a non-empty safe path list")

    expected_paths = {PurePosixPath("package.json")}
    for automatic in ("README", "README.md", "README.txt", "LICENSE", "LICENSE.md",
                      "LICENSE.txt", "NOTICE", "NOTICE.md", "NOTICE.txt"):
        if (path / automatic).is_file():
            expected_paths.add(PurePosixPath(automatic))
    for entry in declared:
        source = path / entry
        if source.is_file():
            expected_paths.add(PurePosixPath(entry))
        elif source.is_dir():
            expected_paths.update(PurePosixPath(item.relative_to(path).as_posix())
                                  for item in source.rglob("*") if item.is_file())
        else:
            raise ValueError(f"npm package.json files entry is missing: {entry}")

    entries = []
    for relative in sorted(expected_paths, key=str):
        source = path / relative
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        entries.append({"path": str(relative), "sha256": digest, "size": source.stat().st_size})
    return entries


def compare_exact(expected: list[dict], actual: list[dict]) -> list[dict]:
    expected_by_path = {item["path"]: item for item in expected}
    actual_by_path = {item["path"]: item for item in actual}
    comparisons = []
    for path in sorted(expected_by_path.keys() | actual_by_path.keys()):
        wanted, found = expected_by_path.get(path), actual_by_path.get(path)
        if wanted is None:
            status = "unexpected"
        elif found is None:
            status = "missing"
        elif wanted["sha256"] != found["sha256"] or wanted["size"] != found["size"]:
            status = "mismatched"
        else:
            status = "matched"
        comparisons.append({"path": path, "expected_sha256": wanted["sha256"] if wanted else None,
                            "actual_sha256": found["sha256"] if found else None, "status": status})
    return comparisons


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
    parser.add_argument("--npm-package", type=Path, required=True)
    parser.add_argument("--npm-source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        inventory = json.loads(args.inventory.read_text(encoding="utf-8"))
        web = inspect_archive(args.web_archive, False)
        npm = inspect_archive(args.npm_package, True)
        npm_expected = inspect_npm_source(args.npm_source)
        npm_comparisons = compare_exact(npm_expected, npm)
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
        npm_failures = [item for item in npm_comparisons if item["status"] != "matched"]
        if npm_failures:
            raise ValueError("npm candidate does not exactly match prepared source/package expectations: " +
                             ", ".join(f"{item['path']} ({item['status']})" for item in npm_failures))
        report = {
            "schema_version": 1,
            "source_revision": inventory["source_revision"],
            "approval": "NOT APPROVED - engineering artifact comparison only",
            "artifacts": [
                {"name": args.web_archive.name, "kind": "flutter-web-tar", "contents": web,
                 "inventory_asset_comparisons": comparisons,
                 "scope_note": "Tracked web/pubspec assets are hash-compared; generated compiled files are recorded but have no source-asset identity."},
                {"name": args.npm_package.name, "kind": "npm-package-tar", "contents": npm,
                 "source_comparisons": npm_comparisons,
                 "scope_note": "Package files are recorded; declared runtime dependencies are inventory scope but are not embedded in the npm tarball."},
            ],
            "limitations": "Native applications and the hosted Worker are absent from this workflow and are not verified by this report.",
        }
        args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (OSError, KeyError, json.JSONDecodeError, tarfile.TarError, ValueError) as exc:
        print(f"Release candidate verification failed: {exc}", file=__import__('sys').stderr)
        return 1
    print(f"Verified candidate contents against available inventory scope: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
