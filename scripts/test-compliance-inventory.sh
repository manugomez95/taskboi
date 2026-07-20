#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/taskboi-compliance-test.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

python3 "$REPO_ROOT/scripts/generate-compliance-inventory.py" --repo "$REPO_ROOT" --output-dir "$test_dir/one" >/dev/null
python3 "$REPO_ROOT/scripts/generate-compliance-inventory.py" --repo "$REPO_ROOT" --output-dir "$test_dir/two" >/dev/null
cmp "$test_dir/one/oss-compliance-inventory.json" "$test_dir/two/oss-compliance-inventory.json"
cmp "$test_dir/one/oss-compliance-inventory.md" "$test_dir/two/oss-compliance-inventory.md"
cmp "$test_dir/one/oss-compliance-sbom.spdx.json" "$test_dir/two/oss-compliance-sbom.spdx.json"
cmp "$test_dir/one/OSS-COMPLIANCE-SHA256SUMS" "$test_dir/two/OSS-COMPLIANCE-SHA256SUMS"

python3 - "$test_dir/one/oss-compliance-inventory.json" "$(git -C "$REPO_ROOT" rev-parse HEAD)" <<'PY'
import json
import sys

inventory = json.load(open(sys.argv[1], encoding="utf-8"))
assert inventory["source_revision"] == sys.argv[2]
assert any(x["ecosystem"] == "dart" and x["license_expression"] == "NOASSERTION"
           for x in inventory["dependencies"])
assert any(x["path"] == "web/sqlite3.wasm" and x["provenance_status"] == "NOASSERTION"
           and len(x["sha256"]) == 64 for x in inventory["assets"])
assert any(x["path"] == "ios/Podfile.lock" for x in inventory["resolution_gaps"])
assert any(x["path"] == "android/**/gradle.lockfile" for x in inventory["resolution_gaps"])
assert inventory["lgpl_expressions"]
assert all(x["distribution"]["current_candidate"] == "not-entering"
           for x in inventory["lgpl_expressions"])
assert all(set(("name", "version", "license_expression")) <= set(x)
           for x in inventory["dependencies"] if x["ecosystem"] == "npm")
assert inventory["unknown_license_dependencies"]
assert any(x["path"] == "web/sqlite3.wasm" for x in inventory["unknown_provenance_assets"])
assert any(x["path"].startswith("ios/Runner/Assets.xcassets/AppIcon.appiconset/")
           for x in inventory["assets"])
PY

python3 - "$test_dir/one/oss-compliance-sbom.spdx.json" <<'PY'
import json
import sys
document = json.load(open(sys.argv[1], encoding="utf-8"))
assert document["spdxVersion"] == "SPDX-2.3"
assert document["packages"]
PY
python3 "$REPO_ROOT/scripts/validate-spdx.py" "$test_dir/one/oss-compliance-sbom.spdx.json" >/dev/null

# The repository-owned validator must reject broken references, syntax, and unknown SPDX identifiers.
python3 - "$test_dir/one/oss-compliance-sbom.spdx.json" "$test_dir/syft-omitted-describes.spdx.json" \
  "$test_dir/missing-describes.spdx.json" \
  "$test_dir/bad-reference.spdx.json" \
  "$test_dir/bad-license.spdx.json" "$test_dir/unknown-license.spdx.json" \
  "$test_dir/unknown-exception.spdx.json" "$test_dir/undefined-license-ref.spdx.json" <<'PY'
import copy
import json
import sys
document = json.load(open(sys.argv[1], encoding="utf-8"))
syft_omitted_describes = copy.deepcopy(document)
# Syft SPDX JSON emitted for the release workflow represents the document root
# with a DESCRIBES relationship while omitting documentDescribes.
syft_omitted_describes.pop("documentDescribes")
missing_describes = copy.deepcopy(syft_omitted_describes)
missing_describes["relationships"] = [
    relationship for relationship in missing_describes["relationships"]
    if not (relationship.get("spdxElementId") == "SPDXRef-DOCUMENT"
            and relationship.get("relationshipType") == "DESCRIBES")
]
bad_reference = copy.deepcopy(document)
bad_reference["relationships"][0]["relatedSpdxElement"] = "SPDXRef-missing"
bad_license = copy.deepcopy(document)
bad_license["packages"][0]["licenseDeclared"] = "not a valid expression!"
unknown_license = copy.deepcopy(document)
unknown_license["packages"][0]["licenseDeclared"] = "Unknown-But-Syntactically-Valid-9.9"
unknown_exception = copy.deepcopy(document)
unknown_exception["packages"][0]["licenseDeclared"] = "GPL-2.0-only WITH Unknown-exception"
undefined_license_ref = copy.deepcopy(document)
undefined_license_ref["packages"][0]["licenseDeclared"] = "LicenseRef-undefined"
for path, value in ((sys.argv[2], syft_omitted_describes), (sys.argv[3], missing_describes),
                    (sys.argv[4], bad_reference), (sys.argv[5], bad_license),
                    (sys.argv[6], unknown_license), (sys.argv[7], unknown_exception),
                    (sys.argv[8], undefined_license_ref)):
    with open(path, "w", encoding="utf-8") as output:
        json.dump(value, output)
PY
python3 "$REPO_ROOT/scripts/validate-spdx.py" "$test_dir/syft-omitted-describes.spdx.json" >/dev/null
if python3 "$REPO_ROOT/scripts/validate-spdx.py" "$test_dir/missing-describes.spdx.json" >/dev/null 2>&1; then
  echo "SPDX validator accepted a document without documentDescribes or a document-root DESCRIBES relationship" >&2
  exit 1
fi
if python3 "$REPO_ROOT/scripts/validate-spdx.py" "$test_dir/bad-reference.spdx.json" >/dev/null 2>&1; then
  echo "SPDX validator accepted an unknown relationship reference" >&2
  exit 1
fi
if python3 "$REPO_ROOT/scripts/validate-spdx.py" "$test_dir/bad-license.spdx.json" >/dev/null 2>&1; then
  echo "SPDX validator accepted an invalid license expression" >&2
  exit 1
fi
if python3 "$REPO_ROOT/scripts/validate-spdx.py" "$test_dir/unknown-license.spdx.json" >/dev/null 2>&1; then
  echo "SPDX validator accepted an unknown license identifier" >&2
  exit 1
fi
if python3 "$REPO_ROOT/scripts/validate-spdx.py" "$test_dir/unknown-exception.spdx.json" >/dev/null 2>&1; then
  echo "SPDX validator accepted an unknown exception identifier" >&2
  exit 1
fi
if python3 "$REPO_ROOT/scripts/validate-spdx.py" "$test_dir/undefined-license-ref.spdx.json" >/dev/null 2>&1; then
  echo "SPDX validator accepted an undefined LicenseRef" >&2
  exit 1
fi

# Build representative candidate archives and compare their real members to inventory scope.
mkdir -p "$test_dir/web" "$test_dir/npm-source/dist" "$test_dir/npm-source/bin" "$test_dir/npm/package"
python3 - "$test_dir/one/oss-compliance-inventory.json" "$REPO_ROOT" "$test_dir/web" <<'PY'
import json
import pathlib
import shutil
import sys
inventory = json.load(open(sys.argv[1], encoding="utf-8"))
repo, output = pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3])
for item in inventory["assets"]:
    if item["distribution"]["current_candidate"] == "expected-in-web-archive":
        path = item["path"]
        # Flutter preserves the pubspec assets/ prefix below build/web/assets/.
        target = output / (path[4:] if path.startswith("web/") else f"assets/{path}")
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(repo / item["path"], target)
PY
printf '%s\n' '{"name":"taskboi-mcp","version":"1.0.0","files":["dist","bin"]}' >"$test_dir/npm-source/package.json"
printf '%s\n' '# Package readme' >"$test_dir/npm-source/README.md"
printf '%s\n' 'compiled output' >"$test_dir/npm-source/dist/index.js"
printf '%s\n' 'cli entry' >"$test_dir/npm-source/bin/taskboi-mcp.js"
cp -R "$test_dir/npm-source/." "$test_dir/npm/package/"
tar -czf "$test_dir/taskboi-web.tar.gz" -C "$test_dir/web" .
tar -czf "$test_dir/taskboi-mcp-1.0.0.tgz" -C "$test_dir/npm" package
python3 "$REPO_ROOT/scripts/verify-release-candidate.py" \
  --inventory "$test_dir/one/oss-compliance-inventory.json" \
  --web-archive "$test_dir/taskboi-web.tar.gz" \
  --npm-package "$test_dir/taskboi-mcp-1.0.0.tgz" \
  --npm-source "$test_dir/npm-source" \
  --output "$test_dir/comparison.json" >/dev/null
grep -F 'NOT APPROVED - engineering artifact comparison only' "$test_dir/comparison.json" >/dev/null

if python3 "$REPO_ROOT/scripts/verify-release-candidate.py" \
  --inventory "$test_dir/one/oss-compliance-inventory.json" \
  --web-archive "$test_dir/absent.tar.gz" \
  --npm-package "$test_dir/taskboi-mcp-1.0.0.tgz" \
  --npm-source "$test_dir/npm-source" \
  --output "$test_dir/absent.json" >/dev/null 2>&1; then
  echo "Candidate verification accepted an absent artifact" >&2
  exit 1
fi
if python3 "$REPO_ROOT/scripts/verify-release-candidate.py" \
  --inventory "$test_dir/one/oss-compliance-inventory.json" \
  --web-archive "$test_dir/taskboi-web.tar.gz" \
  --npm-package "$test_dir/absent.tgz" \
  --npm-source "$test_dir/npm-source" \
  --output "$test_dir/absent-npm.json" >/dev/null 2>&1; then
  echo "Candidate verification accepted an absent npm artifact" >&2
  exit 1
fi
printf '\nmodified\n' >>"$test_dir/web/sqlite3.wasm"
tar -czf "$test_dir/mismatched-web.tar.gz" -C "$test_dir/web" .
if python3 "$REPO_ROOT/scripts/verify-release-candidate.py" \
  --inventory "$test_dir/one/oss-compliance-inventory.json" \
  --web-archive "$test_dir/mismatched-web.tar.gz" \
  --npm-package "$test_dir/taskboi-mcp-1.0.0.tgz" \
  --npm-source "$test_dir/npm-source" \
  --output "$test_dir/mismatch.json" >/dev/null 2>&1; then
  echo "Candidate verification accepted an inventory hash mismatch" >&2
  exit 1
fi

# npm contents must fail closed for extra, absent, and content-mismatched members.
for scenario in unexpected missing mismatched; do
  rm -rf "$test_dir/npm-negative"
  cp -R "$test_dir/npm" "$test_dir/npm-negative"
  case "$scenario" in
    unexpected) printf '%s\n' 'not declared' >"$test_dir/npm-negative/package/unexpected.txt" ;;
    missing) rm "$test_dir/npm-negative/package/dist/index.js" ;;
    mismatched) printf '%s\n' 'tampered output' >"$test_dir/npm-negative/package/dist/index.js" ;;
  esac
  tar -czf "$test_dir/npm-$scenario.tgz" -C "$test_dir/npm-negative" package
  if python3 "$REPO_ROOT/scripts/verify-release-candidate.py" \
    --inventory "$test_dir/one/oss-compliance-inventory.json" \
    --web-archive "$test_dir/taskboi-web.tar.gz" \
    --npm-package "$test_dir/npm-$scenario.tgz" \
    --npm-source "$test_dir/npm-source" \
    --output "$test_dir/npm-$scenario.json" >/dev/null 2>&1; then
    echo "Candidate verification accepted $scenario npm contents" >&2
    exit 1
  fi
done

(cd "$test_dir/one" && shasum -a 256 -c OSS-COMPLIANCE-SHA256SUMS >/dev/null)

# A dirty lockfile must not affect evidence pinned to the committed revision.
cp "$REPO_ROOT/pubspec.lock" "$test_dir/pubspec.lock"
trap 'cp "$test_dir/pubspec.lock" "$REPO_ROOT/pubspec.lock"; rm -rf "$test_dir"' EXIT
printf '\n# uncommitted test mutation\n' >> "$REPO_ROOT/pubspec.lock"
python3 "$REPO_ROOT/scripts/generate-compliance-inventory.py" --repo "$REPO_ROOT" \
  --revision HEAD --output-dir "$test_dir/dirty" >/dev/null
cmp "$test_dir/one/oss-compliance-inventory.json" "$test_dir/dirty/oss-compliance-inventory.json"
cp "$test_dir/pubspec.lock" "$REPO_ROOT/pubspec.lock"

if python3 "$REPO_ROOT/scripts/check-public-release-approval.py" \
  "$REPO_ROOT/docs/COMPLIANCE_REVIEW.md" \
  --expected-revision "$(git -C "$REPO_ROOT" rev-parse HEAD)" >"$test_dir/gate-output"; then
  echo "Default compliance review unexpectedly passed" >&2
  exit 1
fi
grep -F 'NOT APPROVED' "$test_dir/gate-output" >/dev/null

cat >"$test_dir/approved-review.md" <<'EOF'
- Approval status: APPROVED
- Named human/legal reviewer: Example Reviewer, Legal
- Review date (YYYY-MM-DD): 2026-07-19
- Source revision: REVISION_PLACEHOLDER
- Scoped distribution channels: npm public registry and public web download
- Notices decision: Include reviewed notices in both artifacts
- License texts decision: Include the reviewed license bundle
- Source-offer decision: Written offer required and attached
- Asset provenance attestations: Reviewer checked every inventory asset
- Vulnerability disposition: Findings accepted in the signed risk record
EOF
sed -i.bak "s/REVISION_PLACEHOLDER/$(git -C "$REPO_ROOT" rev-parse HEAD)/" "$test_dir/approved-review.md"
rm "$test_dir/approved-review.md.bak"
python3 "$REPO_ROOT/scripts/check-public-release-approval.py" "$test_dir/approved-review.md" \
  --expected-revision "$(git -C "$REPO_ROOT" rev-parse HEAD)" >/dev/null

release="$REPO_ROOT/.github/workflows/release-candidate.yml"
inventory_line="$(grep -n -F 'scripts/generate-compliance-inventory.py' "$release" | cut -d: -f1)"
verify_line="$(grep -n -F 'scripts/verify-release-candidate.py' "$release" | cut -d: -f1)"
validate_line="$(grep -n -m1 -F 'scripts/validate-spdx.py' "$release" | cut -d: -f1)"
checksum_line="$(grep -n -F 'sha256sum --check --strict SHA256SUMS' "$release" | cut -d: -f1)"
scan_line="$(grep -n -F 'scripts/ci/secret-scan.sh artifacts release' "$release" | cut -d: -f1)"
attest_line="$(grep -n -F 'actions/attest-build-provenance@' "$release" | cut -d: -f1)"
if [[ -z "$inventory_line" || -z "$verify_line" || -z "$validate_line" || -z "$checksum_line" || -z "$scan_line" || -z "$attest_line" ]] ||
  ! (( inventory_line < validate_line && validate_line < verify_line && verify_line < checksum_line && checksum_line < scan_line && scan_line < attest_line )); then
  echo "SPDX and candidate verification plus checksums must precede artifact scan and attestation" >&2
  exit 1
fi
if grep -F 'check-public-release-approval.py' "$release" >/dev/null; then
  echo "Internal release-candidate builds must not require public approval" >&2
  exit 1
fi

echo "Compliance inventory and gate checks passed."
