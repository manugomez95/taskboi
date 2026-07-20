#!/usr/bin/env python3
"""Build deterministic OSS/SBOM review evidence from committed repository inputs."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path, PurePosixPath

NOASSERTION = "NOASSERTION"
LOCK_INPUTS = (
    "pubspec.lock",
    "taskboi-mcp/package-lock.json",
    "taskboi-mcp/workers/package-lock.json",
    "macos/Podfile.lock",
    "macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    "macos/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    "android/settings.gradle",
    "android/build.gradle",
    "android/app/build.gradle",
)
DECLARATION_INPUTS = LOCK_INPUTS + (
    "pubspec.yaml",
    "taskboi-mcp/package.json",
    "taskboi-mcp/workers/package.json",
    "ios/Podfile",
    "macos/Podfile",
    "android/gradle/wrapper/gradle-wrapper.properties",
    ".github/workflows/release-candidate.yml",
)
EXPECTED_NATIVE_LOCKS = ("ios/Podfile.lock",)
MEDIA_BINARY_SUFFIXES = {
    ".aar", ".a", ".bin", ".dll", ".dylib", ".gif", ".icns", ".ico",
    ".jar", ".jpeg", ".jpg", ".mov", ".mp3", ".mp4", ".otf", ".pdf",
    ".png", ".so", ".ttf", ".wasm", ".wav", ".webp", ".zip",
}


def git(repo: Path, *args: str, binary: bool = False):
    result = subprocess.run(
        ["git", "-C", str(repo), *args], check=True, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout
    return result if binary else result.decode("utf-8")


def committed_text(repo: Path, revision: str, path: str) -> str:
    return git(repo, "show", f"{revision}:{path}")


def record(ecosystem: str, name: str, version: str | None, source: str,
           license_expression: str | None = None, **extra):
    item = {
        "ecosystem": ecosystem,
        "name": name,
        "version": version or NOASSERTION,
        "license_expression": license_expression or NOASSERTION,
        "input": source,
    }
    item.update(extra)
    return item


def parse_pub(text: str, source: str):
    items = []
    current = None
    fields: dict[str, str] = {}
    for line in text.splitlines():
        match = re.match(r"^  ([^ ].*):$", line)
        if match:
            if current:
                items.append(record("dart", current, fields.get("version"), source,
                                    dependency_scope=fields.get("dependency", NOASSERTION),
                                    package_source=fields.get("source", NOASSERTION)))
            current, fields = match.group(1), {}
            continue
        if current:
            match = re.match(r'^    (dependency|source|version):\s*["\']?(.+?)["\']?$', line)
            if match:
                fields[match.group(1)] = match.group(2).strip('"\'')
    if current:
        items.append(record("dart", current, fields.get("version"), source,
                            dependency_scope=fields.get("dependency", NOASSERTION),
                            package_source=fields.get("source", NOASSERTION)))
    return items


def npm_name(path: str, metadata: dict) -> str:
    if metadata.get("name"):
        return metadata["name"]
    tail = path.rsplit("node_modules/", 1)[-1]
    return tail


def parse_npm(text: str, source: str):
    data = json.loads(text)
    items = []
    for path, metadata in data.get("packages", {}).items():
        if not path:  # project package, not a third-party dependency
            continue
        scope = "development" if metadata.get("dev") else "production"
        if metadata.get("optional"):
            scope += "+optional"
        items.append(record("npm", npm_name(path, metadata), metadata.get("version"), source,
                            metadata.get("license"), dependency_scope=scope,
                            lockfile_path=path))
    return items


def parse_pods(text: str, source: str):
    items = []
    in_pods = False
    for line in text.splitlines():
        if line == "PODS:":
            in_pods = True
            continue
        if in_pods and line and not line.startswith(" "):
            break
        match = re.match(r"^  - ([^ (]+) \(([^)]+)\)", line) if in_pods else None
        if match:
            items.append(record("cocoapods", match.group(1), match.group(2), source))
    return items


def parse_swift(text: str, source: str):
    items = []
    for pin in json.loads(text).get("pins", []):
        state = pin.get("state", {})
        items.append(record("swift", pin.get("identity", NOASSERTION),
                            state.get("version") or state.get("revision"), source,
                            location=pin.get("location", NOASSERTION),
                            revision=state.get("revision", NOASSERTION)))
    return items


def parse_gradle(text: str, source: str):
    items = []
    plugin = re.compile(r'^\s*id\s+["\']([^"\']+)["\'](?:\s+version\s+["\']([^"\']+)["\'])?')
    dependency = re.compile(r'^\s*(?:api|implementation|compileOnly|runtimeOnly|testImplementation|classpath)\s*[\( ]\s*["\']([^:"\']+):([^:"\']+):([^"\']+)["\']')
    for line in text.splitlines():
        match = plugin.match(line)
        if match:
            items.append(record("gradle-plugin", match.group(1), match.group(2), source))
            continue
        match = dependency.match(line)
        if match:
            items.append(record("gradle", f"{match.group(1)}:{match.group(2)}", match.group(3), source))
    return items


def asset_paths(repo: Path, revision: str) -> list[str]:
    tracked = git(repo, "ls-tree", "-r", "--name-only", revision).splitlines()
    selected = set()
    for path in tracked:
        pure = PurePosixPath(path)
        if pure.suffix.lower() in MEDIA_BINARY_SUFFIXES:
            selected.add(path)
        if path.startswith("web/") and pure.name in {
            "drift_worker.js", "drift_worker.js.deps", "drift_worker.js.map", "sqlite3.wasm"
        }:
            selected.add(path)
        if path.startswith(("android/app/src/main/res/", "ios/Runner/Assets.xcassets/",
                            "macos/Runner/Assets.xcassets/")):
            selected.add(path)
        if path.startswith("web/") and pure.suffix.lower() in {
            ".html", ".json", ".png", ".wasm"
        }:
            selected.add(path)
    # pubspec-declared asset paths are committed inputs; only literal entries are used.
    pubspec = committed_text(repo, revision, "pubspec.yaml")
    in_assets = False
    for line in pubspec.splitlines():
        if re.match(r"^\s*assets:\s*$", line):
            in_assets = True
            continue
        if in_assets:
            match = re.match(r"^\s+-\s+([^#]+?)\s*$", line)
            if match:
                declared = match.group(1).strip('"\'')
                selected.update(p for p in tracked if p == declared or p.startswith(declared.rstrip("/") + "/"))
            elif line and not line.startswith(" "):
                in_assets = False
    return sorted(selected)


def distribution_for_dependency(item: dict) -> dict:
    source = item["input"]
    scope = item.get("dependency_scope", NOASSERTION)
    if source == "taskboi-mcp/workers/package-lock.json":
        return {"current_candidate": "not-entering",
                "basis": "worker project is neither installed, built, nor packed by release-candidate.yml"}
    if source == "taskboi-mcp/package-lock.json":
        if scope.startswith("development"):
            return {"current_candidate": "not-entering",
                    "basis": "development dependency; npm package build output requires artifact verification"}
        return {"current_candidate": "package-metadata-or-runtime-dependency",
                "basis": "taskboi-mcp npm package declares runtime dependencies; npm tar contents require verification"}
    if item["ecosystem"] == "dart":
        if scope == "direct dev" or scope == "transitive" and item["name"].endswith(("_builder", "_generator")):
            return {"current_candidate": "build-only-or-unverified",
                    "basis": "lockfile scope alone does not prove compiled web inclusion"}
        return {"current_candidate": "compiled-in-or-runtime-unverified",
                "basis": "Flutter web build consumes the Dart lock graph; compiled artifact inspection is required"}
    return {"current_candidate": "not-entering",
            "basis": "native platform artifact is not built by release-candidate.yml"}


def distribution_for_asset(path: str) -> dict:
    if path.startswith("web/") or path.startswith("assets/"):
        verification = "presence" if path == "web/index.html" else "source-sha256"
        return {"current_candidate": "expected-in-web-archive",
                "verification": verification,
                "basis": "Flutter web build transforms its entry point and copies other web resources and pubspec-declared assets; verify built archive"}
    return {"current_candidate": "not-entering",
            "verification": "not-applicable",
            "basis": "native platform artifact is not built by release-candidate.yml"}


def spdx_id(prefix: str, value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9.-]", "-", value)
    return f"SPDXRef-{prefix}-{cleaned}"


def spdx_document(inventory: dict) -> dict:
    revision = inventory["source_revision"]
    packages = []
    relationships = []
    for index, item in enumerate(inventory["dependencies"]):
        identifier = spdx_id("Package", f"{index}-{item['ecosystem']}-{item['name']}")
        packages.append({
            "SPDXID": identifier,
            "name": item["name"],
            "versionInfo": item["version"],
            "downloadLocation": "NOASSERTION",
            "filesAnalyzed": False,
            "licenseConcluded": "NOASSERTION",
            "licenseDeclared": item["license_expression"],
            "copyrightText": "NOASSERTION",
            "comment": f"Resolved from {item['input']}; distribution: {item['distribution']['current_candidate']}",
        })
        relationships.append({"spdxElementId": "SPDXRef-DOCUMENT", "relationshipType": "DESCRIBES",
                              "relatedSpdxElement": identifier})
    return {
        "spdxVersion": "SPDX-2.3", "dataLicense": "CC0-1.0", "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"taskboi-source-{revision}",
        "documentNamespace": f"https://taskboi.invalid/spdx/{revision}",
        "creationInfo": {"created": "1970-01-01T00:00:00Z", "creators": ["Tool: generate-compliance-inventory.py"]},
        "documentDescribes": [x["SPDXID"] for x in packages],
        "packages": packages, "relationships": relationships,
        "comment": inventory["disclaimer"],
    }


def markdown(inventory: dict) -> str:
    lines = [
        "# OSS Release Compliance Inventory", "",
        "> Engineering inventory only. This does not assert legal compatibility or release approval.", "",
        f"Source revision: `{inventory['source_revision']}`", "",
        "Missing license or provenance evidence is recorded as `NOASSERTION`.", "",
        "## Inputs", "", "| Committed input | SHA-256 |", "|---|---|",
    ]
    lines += [f"| `{x['path']}` | `{x['sha256']}` |" for x in inventory["inputs"]]
    lines += ["", "## Dependencies", "", "| Ecosystem | Name | Version | License expression | Candidate entry | Input |",
              "|---|---|---|---|---|---|"]
    for item in inventory["dependencies"]:
        values = [item[k] for k in ("ecosystem", "name", "version", "license_expression")]
        values += [item["distribution"]["current_candidate"], item["input"]]
        lines.append("| " + " | ".join(str(v).replace("|", "\\|") for v in values) + " |")
    lines += ["", "## Tracked bundled, binary, and media assets", "",
              "| Path | SHA-256 | Provenance status | Candidate entry |", "|---|---|---|---|"]
    lines += [f"| `{x['path']}` | `{x['sha256']}` | {x['provenance_status']} | "
              f"{x['distribution']['current_candidate']} |" for x in inventory["assets"]]
    lines += ["", "## Unknown license and provenance findings", "",
              f"- Dependencies with unknown declared license: **{len(inventory['unknown_license_dependencies'])}**",
              f"- Assets with unverified provenance: **{len(inventory['unknown_provenance_assets'])}**", "",
              "These findings require human review; they are not license or provenance conclusions."]
    lines += ["", "## Current candidate distribution assessment", "",
              "This is an engineering artifact-entry classification, not a license decision.", "",
              "| LGPL package | Version | Expression | Current candidate | Basis |",
              "|---|---|---|---|---|"]
    for item in inventory["lgpl_expressions"]:
        dist = item["distribution"]
        lines.append(f"| {item['name']} | {item['version']} | {item['license_expression']} | "
                     f"{dist['current_candidate']} | {dist['basis']} |")
    lines += ["", "## Resolution gaps", "", "| Missing input | Impact |", "|---|---|"]
    lines += [f"| `{x['path']}` | {x['impact']} |" for x in inventory["resolution_gaps"]]
    return "\n".join(lines) + "\n"


def build(repo: Path, revision_arg: str):
    revision = git(repo, "rev-parse", f"{revision_arg}^{{commit}}").strip()
    texts = {path: committed_text(repo, revision, path) for path in LOCK_INPUTS}
    dependencies = []
    dependencies += parse_pub(texts["pubspec.lock"], "pubspec.lock")
    for path in LOCK_INPUTS[1:3]:
        dependencies += parse_npm(texts[path], path)
    dependencies += parse_pods(texts["macos/Podfile.lock"], "macos/Podfile.lock")
    for path in LOCK_INPUTS[4:6]:
        dependencies += parse_swift(texts[path], path)
    for path in LOCK_INPUTS[6:]:
        dependencies += parse_gradle(texts[path], path)
    dependencies.sort(key=lambda x: (x["ecosystem"], x["name"], x["version"], x["input"]))
    for item in dependencies:
        item["distribution"] = distribution_for_dependency(item)

    def digest(path: str) -> str:
        return hashlib.sha256(git(repo, "show", f"{revision}:{path}", binary=True)).hexdigest()

    inputs = [{"path": path, "sha256": digest(path)} for path in DECLARATION_INPUTS]
    assets = [{"path": path, "sha256": digest(path), "provenance_status": NOASSERTION,
               "distribution": distribution_for_asset(path)}
              for path in asset_paths(repo, revision)]
    tracked = set(git(repo, "ls-tree", "-r", "--name-only", revision).splitlines())
    gaps = [{"path": path, "status": "missing", "impact": "iOS CocoaPods resolution is not reproducibly locked"}
            for path in EXPECTED_NATIVE_LOCKS if path not in tracked]
    if not any(path == "android/gradle.lockfile" or
               path.startswith("android/gradle/dependency-locks/") or
               path.endswith("/gradle.lockfile") for path in tracked):
        gaps.append({"path": "android/**/gradle.lockfile", "status": "missing",
                     "impact": "Gradle/Maven declarations are inventoried, but the resolved artifact graph is not locked"})
    lgpl = [{"name": x["name"], "version": x["version"], "license_expression": x["license_expression"],
             "input": x["input"], "distribution": x["distribution"]}
            for x in dependencies if "LGPL" in x["license_expression"]]
    unknown_licenses = [{"ecosystem": x["ecosystem"], "name": x["name"],
                         "version": x["version"], "input": x["input"]}
                        for x in dependencies if x["license_expression"] == NOASSERTION]
    unknown_provenance = [{"path": x["path"], "sha256": x["sha256"],
                           "distribution": x["distribution"]} for x in assets
                          if x["provenance_status"] == NOASSERTION]
    return {"schema_version": 3, "source_revision": revision, "inputs": inputs,
            "dependencies": dependencies, "assets": assets,
            "resolution_gaps": gaps, "lgpl_expressions": lgpl,
            "unknown_license_dependencies": unknown_licenses,
            "unknown_provenance_assets": unknown_provenance,
            "candidate_artifacts": [
                {"name": "taskboi-web.tar.gz", "surface": "Flutter web", "built_by_current_workflow": True},
                {"name": "taskboi-mcp npm tarball", "surface": "npm package", "built_by_current_workflow": True},
                {"name": "taskboi Worker", "surface": "hosted Worker", "built_by_current_workflow": False},
                {"name": "native applications", "surface": "Android/iOS/macOS/Windows/Linux", "built_by_current_workflow": False},
            ],
            "disclaimer": "Engineering inventory only; no legal compatibility or release approval is asserted."}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--revision", default="HEAD")
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    inventory = build(args.repo.resolve(), args.revision)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "oss-compliance-inventory.json").write_text(
        json.dumps(inventory, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (args.output_dir / "oss-compliance-inventory.md").write_text(markdown(inventory), encoding="utf-8")
    (args.output_dir / "oss-compliance-sbom.spdx.json").write_text(
        json.dumps(spdx_document(inventory), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    checksum_lines = []
    for name in ("oss-compliance-inventory.json", "oss-compliance-inventory.md",
                 "oss-compliance-sbom.spdx.json"):
        checksum_lines.append(f"{hashlib.sha256((args.output_dir / name).read_bytes()).hexdigest()}  {name}")
    (args.output_dir / "OSS-COMPLIANCE-SHA256SUMS").write_text(
        "\n".join(checksum_lines) + "\n", encoding="utf-8")
    print(f"Wrote compliance inventory for {inventory['source_revision']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
