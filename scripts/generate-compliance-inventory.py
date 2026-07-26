#!/usr/bin/env python3
"""Generate deterministic compliance evidence for the committed public MCP core."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

NOASSERTION = "NOASSERTION"
SCOPE_ROOT = "taskboi-mcp"
SCOPE_EXCLUDES = ("taskboi-mcp/workers",)
ASSET_SUFFIXES = {
    ".a", ".bin", ".dll", ".dylib", ".gif", ".ico", ".jpeg", ".jpg",
    ".mp3", ".mp4", ".otf", ".pdf", ".png", ".so", ".ttf", ".wasm",
    ".wav", ".webp", ".zip",
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
    paths = git(repo, "ls-tree", "-r", "--name-only", revision, "--", SCOPE_ROOT).splitlines()
    return sorted(
        path for path in paths
        if not any(path == excluded or path.startswith(excluded + "/")
                   for excluded in SCOPE_EXCLUDES)
    )


def dependencies(repo: Path, revision: str) -> list[dict]:
    source = f"{SCOPE_ROOT}/package-lock.json"
    lock = json.loads(committed_bytes(repo, revision, source))
    found = []
    for lock_path, metadata in lock.get("packages", {}).items():
        if not lock_path:
            continue
        name = metadata.get("name") or lock_path.rsplit("node_modules/", 1)[-1]
        found.append({
            "ecosystem": "npm",
            "name": name,
            "version": metadata.get("version") or NOASSERTION,
            "license_expression": metadata.get("license") or NOASSERTION,
            "input": source,
            "dependency_scope": "development" if metadata.get("dev") else "production",
        })
    return sorted(found, key=lambda item: (item["name"], item["version"]))


def spdx_id(prefix: str, value: str) -> str:
    return f"SPDXRef-{prefix}-" + re.sub(r"[^A-Za-z0-9.-]+", "-", value).strip("-")


def spdx_document(inventory: dict) -> dict:
    revision = inventory["source_revision"]
    root_id = "SPDXRef-Package-taskboi-mcp"
    packages = [{
        "SPDXID": root_id,
        "name": "taskboi-mcp",
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
        "name": f"taskboi-mcp-source-{revision}",
        "documentNamespace": f"https://taskboi.invalid/spdx/taskboi-mcp/{revision}",
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
        "# Public MCP Core Compliance Inventory",
        "",
        "> Engineering evidence only. This does not grant public release approval.",
        "",
        f"Source revision: `{inventory['source_revision']}`",
        "",
        "Scope: committed files under `taskboi-mcp/`, excluding `taskboi-mcp/workers/`.",
        "",
        "Unknown license or asset provenance is preserved as `NOASSERTION`.",
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
    return "\n".join(lines) + "\n"


def build(repo: Path, revision_arg: str) -> dict:
    revision = git(repo, "rev-parse", f"{revision_arg}^{{commit}}").strip()
    paths = scope_paths(repo, revision)
    if not paths:
        raise ValueError("public MCP source scope is empty")
    inputs = [{
        "path": path,
        "sha256": hashlib.sha256(committed_bytes(repo, revision, path)).hexdigest(),
    } for path in paths]
    deps = dependencies(repo, revision)
    assets = [{
        "path": item["path"],
        "sha256": item["sha256"],
        "provenance_status": NOASSERTION,
    } for item in inputs if Path(item["path"]).suffix.lower() in ASSET_SUFFIXES]
    return {
        "schema_version": 4,
        "source_revision": revision,
        "scope": {
            "kind": "committed-source",
            "root": SCOPE_ROOT,
            "excludes": list(SCOPE_EXCLUDES),
        },
        "scope_paths": paths,
        "inputs": inputs,
        "dependencies": deps,
        "assets": assets,
        "unknown_license_dependencies": [
            item for item in deps if item["license_expression"] == NOASSERTION
        ],
        "unknown_provenance_assets": [
            item for item in assets if item["provenance_status"] == NOASSERTION
        ],
        "disclaimer": "Engineering evidence only; no public release approval is asserted.",
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
