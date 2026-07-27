#!/usr/bin/env python3
"""Generate deterministic compliance evidence for the committed public core."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

NOASSERTION = "NOASSERTION"
SCOPE_ROOT = "."
SCOPE_EXCLUDES: tuple[str, ...] = ()
ASSET_SUFFIXES = {
    ".a", ".bin", ".dll", ".dylib", ".gif", ".ico", ".jpeg", ".jpg",
    ".mp3", ".mp4", ".otf", ".pdf", ".png", ".so", ".ttf", ".wasm",
    ".wav", ".webp", ".zip",
}
AUTOMATED_DEPENDENCY_INPUTS = ("pubspec.lock",)
FINAL_REVIEW_LOCKS = {
    "deno.lock": "Deno dependencies",
    "macos/Podfile.lock": "CocoaPods dependencies",
    "macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved":
        "Swift package dependencies",
    "macos/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved":
        "Swift package dependencies",
}


def git(repo: Path, *args: str, binary: bool = False):
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout
    return result if binary else result.decode("utf-8")


def committed_bytes(repo: Path, revision: str, path: str) -> bytes:
    return git(repo, "show", f"{revision}:{path}", binary=True)


def scope_paths(repo: Path, revision: str) -> list[str]:
    paths = git(repo, "ls-tree", "-r", "--name-only", revision).splitlines()
    return sorted(
        path for path in paths
        if not any(path == excluded or path.startswith(excluded + "/")
                   for excluded in SCOPE_EXCLUDES)
    )


def dependencies(repo: Path, revision: str) -> list[dict]:
    source = "pubspec.lock"
    lock = committed_bytes(repo, revision, source).decode("utf-8")
    found = []
    current_name = None
    current_version = None
    current_scope = "production"
    for line in lock.splitlines():
        package = re.match(r"^  ([A-Za-z0-9_+.-]+):$", line)
        if package:
            if current_name and current_version:
                found.append({
                    "ecosystem": "pub",
                    "name": current_name,
                    "version": current_version,
                    "license_expression": NOASSERTION,
                    "input": source,
                    "dependency_scope": current_scope,
                })
            current_name = package.group(1)
            current_version = None
            current_scope = "production"
            continue
        if current_name:
            dependency = re.match(r"^    dependency: (.+)$", line)
            version = re.match(r'^    version: "([^"]+)"$', line)
            if dependency:
                current_scope = (
                    "development" if dependency.group(1).startswith("direct dev")
                    else "production"
                )
            elif version:
                current_version = version.group(1)
    if current_name and current_version:
        found.append({
            "ecosystem": "pub",
            "name": current_name,
            "version": current_version,
            "license_expression": NOASSERTION,
            "input": source,
            "dependency_scope": current_scope,
        })
    return sorted(found, key=lambda item: (item["name"], item["version"]))


def spdx_id(prefix: str, value: str) -> str:
    return f"SPDXRef-{prefix}-" + re.sub(r"[^A-Za-z0-9.-]+", "-", value).strip("-")


def spdx_document(inventory: dict) -> dict:
    revision = inventory["source_revision"]
    root_id = "SPDXRef-Package-taskboi"
    packages = [{
        "SPDXID": root_id,
        "name": "taskboi",
        "versionInfo": revision,
        "downloadLocation": "NOASSERTION",
        "filesAnalyzed": False,
        "licenseConcluded": "NOASSERTION",
        "licenseDeclared": "Apache-2.0",
        "copyrightText": "NOASSERTION",
    }]
    relationships = [{
        "spdxElementId": "SPDXRef-DOCUMENT",
        "relationshipType": "DESCRIBES",
        "relatedSpdxElement": root_id,
    }]
    used_ids = {root_id}
    for index, item in enumerate(inventory["dependencies"]):
        identifier = spdx_id("Package", f"{index}-{item['name']}")
        while identifier in used_ids:
            identifier += "-duplicate"
        used_ids.add(identifier)
        packages.append({
            "SPDXID": identifier,
            "name": item["name"],
            "versionInfo": item["version"],
            "downloadLocation": "NOASSERTION",
            "filesAnalyzed": False,
            "licenseConcluded": "NOASSERTION",
            "licenseDeclared": item["license_expression"],
            "copyrightText": "NOASSERTION",
            "comment": f"Resolved from {item['input']}",
        })
        relationships.append({
            "spdxElementId": root_id,
            "relationshipType": "DEPENDS_ON",
            "relatedSpdxElement": identifier,
        })
    return {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"taskboi-source-{revision}",
        "documentNamespace": f"https://taskboi.invalid/spdx/taskboi/{revision}",
        "creationInfo": {
            "created": "1970-01-01T00:00:00Z",
            "creators": ["Tool: generate-compliance-inventory.py"],
        },
        "documentDescribes": [root_id],
        "packages": packages,
        "relationships": relationships,
        "comment": inventory["disclaimer"],
    }


def markdown(inventory: dict) -> str:
    lines = [
        "# Public Core Compliance Inventory",
        "",
        "> Engineering evidence only. This does not grant public release approval.",
        "",
        f"Source revision: `{inventory['source_revision']}`",
        "",
        "Scope: all committed files in the public core repository.",
        "",
        "Unknown license or asset provenance is preserved as `NOASSERTION`.",
        "",
        "Automated dependency package coverage is deliberately limited to "
        "`pubspec.lock`. Committed Deno and native lockfiles are recorded below "
        "as requiring final review; their packages are not represented as parsed "
        "dependencies or SPDX package relationships.",
        "",
        "## Committed inputs",
        "",
        "| Path | SHA-256 |",
        "|---|---|",
    ]
    lines.extend(f"| `{item['path']}` | `{item['sha256']}` |"
                 for item in inventory["inputs"])
    lines.extend([
        "",
        "## Resolved dependencies",
        "",
        "| Name | Version | License | Input |",
        "|---|---|---|---|",
    ])
    lines.extend(
        f"| {item['name']} | {item['version']} | {item['license_expression']} | "
        f"`{item['input']}` |"
        for item in inventory["dependencies"]
    )
    lines.extend([
        "",
        "## Dependency locks requiring final review",
        "",
        "| Path | Surface | Automated package coverage |",
        "|---|---|---|",
    ])
    lines.extend(
        f"| `{item['path']}` | {item['surface']} | {item['automated_coverage']} |"
        for item in inventory["dependency_coverage"]["final_review_required"]
    )
    return "\n".join(lines) + "\n"


def build(repo: Path, revision_arg: str) -> dict:
    revision = git(repo, "rev-parse", f"{revision_arg}^{{commit}}").strip()
    paths = scope_paths(repo, revision)
    if not paths:
        raise ValueError("public core source scope is empty")
    inputs = [{
        "path": path,
        "sha256": hashlib.sha256(committed_bytes(repo, revision, path)).hexdigest(),
    } for path in paths]
    deps = dependencies(repo, revision)
    final_review_locks = [{
        "path": path,
        "surface": surface,
        "automated_coverage": "none",
        "review_gate": "required-before-artifact-or-package-publication",
    } for path, surface in FINAL_REVIEW_LOCKS.items() if path in paths]
    assets = []
    for item in inputs:
        if item["path"] == "web/index.html":
            assets.append({
                "path": item["path"],
                "sha256": item["sha256"],
                "provenance_status": NOASSERTION,
                "distribution": {
                    "current_candidate": "expected-in-web-archive",
                    "verification": "presence",
                },
            })
            continue
        if Path(item["path"]).suffix.lower() not in ASSET_SUFFIXES:
            continue
        asset = {
            "path": item["path"],
            "sha256": item["sha256"],
            "provenance_status": NOASSERTION,
            "distribution": {"current_candidate": "not-entering"},
        }
        if item["path"].startswith("assets/"):
            asset["distribution"] = {
                "current_candidate": "expected-in-web-archive",
                "verification": "source-sha256",
            }
        assets.append(asset)
    return {
        "schema_version": 5,
        "source_revision": revision,
        "scope": {
            "kind": "committed-source",
            "root": SCOPE_ROOT,
            "excludes": list(SCOPE_EXCLUDES),
        },
        "scope_paths": paths,
        "inputs": inputs,
        "dependency_coverage": {
            "automated_package_inputs": list(AUTOMATED_DEPENDENCY_INPUTS),
            "automated_package_ecosystems": ["pub"],
            "final_review_required": final_review_locks,
            "complete_dependency_bom": False,
        },
        "dependencies": deps,
        "assets": assets,
        "unknown_license_dependencies": [
            item for item in deps if item["license_expression"] == NOASSERTION
        ],
        "unknown_provenance_assets": [
            item for item in assets if item["provenance_status"] == NOASSERTION
        ],
        "disclaimer": (
            "Engineering evidence only; no public release approval is asserted. "
            "Automated dependency package and SPDX relationship coverage is "
            "limited to pubspec.lock; recorded Deno and native locks require "
            "final review and have no automated package coverage."
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--revision", default="HEAD")
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    inventory = build(args.repo.resolve(), args.revision)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    outputs = {
        "oss-compliance-inventory.json":
            json.dumps(inventory, indent=2, sort_keys=True) + "\n",
        "oss-compliance-inventory.md": markdown(inventory),
        "oss-compliance-sbom.spdx.json":
            json.dumps(spdx_document(inventory), indent=2, sort_keys=True) + "\n",
    }
    for name, content in outputs.items():
        (args.output_dir / name).write_text(content, encoding="utf-8")
    checksums = [
        f"{hashlib.sha256((args.output_dir / name).read_bytes()).hexdigest()}  {name}"
        for name in outputs
    ]
    (args.output_dir / "OSS-COMPLIANCE-SHA256SUMS").write_text(
        "\n".join(checksums) + "\n", encoding="utf-8"
    )
    print(f"Wrote compliance inventory for {inventory['source_revision']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
