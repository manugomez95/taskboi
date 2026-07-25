#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/taskboi-compliance-test.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
readonly HEAD_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD)"

python3 "$REPO_ROOT/scripts/generate-compliance-inventory.py" \
  --repo "$REPO_ROOT" --revision HEAD --output-dir "$test_dir/evidence"
python3 "$REPO_ROOT/scripts/generate-compliance-inventory.py" \
  --repo "$REPO_ROOT" --revision HEAD --output-dir "$test_dir/evidence-repeat" >/dev/null
for evidence_file in oss-compliance-inventory.json oss-compliance-inventory.md \
  oss-compliance-sbom.spdx.json OSS-COMPLIANCE-SHA256SUMS; do
  cmp "$test_dir/evidence/$evidence_file" "$test_dir/evidence-repeat/$evidence_file"
done

python3 - "$test_dir/evidence/oss-compliance-inventory.json" "$HEAD_SHA" <<'PY'
import json
import sys

inventory = json.load(open(sys.argv[1], encoding="utf-8"))
assert inventory["source_revision"] == sys.argv[2]
assert inventory["scope"] == {
    "kind": "committed-source",
    "root": "taskboi-mcp",
    "excludes": ["taskboi-mcp/workers"],
}
assert inventory["inputs"]
assert all(item["path"].startswith("taskboi-mcp/") for item in inventory["inputs"])
assert all(not item["path"].startswith("taskboi-mcp/workers/") for item in inventory["inputs"])
assert {item["path"] for item in inventory["inputs"]} == set(
    inventory["scope_paths"]
)
assert all(len(item["sha256"]) == 64 for item in inventory["inputs"])
assert inventory["dependencies"]
assert all(
    {"name", "version", "license_expression", "input"} <= set(item)
    for item in inventory["dependencies"]
)
assert inventory["assets"] == []
assert inventory["unknown_provenance_assets"] == []
PY

python3 "$REPO_ROOT/scripts/validate-spdx.py" \
  "$test_dir/evidence/oss-compliance-sbom.spdx.json"
(cd "$test_dir/evidence" && shasum -a 256 -c OSS-COMPLIANCE-SHA256SUMS)

# Unknown license metadata and source asset provenance must never be guessed.
fixture="$test_dir/fixture"
mkdir -p "$fixture/taskboi-mcp/src"
git -C "$fixture" init -q
git -C "$fixture" config user.name "Compliance Test"
git -C "$fixture" config user.email "compliance-test@example.invalid"
printf '%s\n' '{"name":"fixture","version":"1.0.0"}' >"$fixture/taskboi-mcp/package.json"
printf '%s\n' '{"lockfileVersion":3,"packages":{"":{"name":"fixture","version":"1.0.0"},"node_modules/unknown-package":{"version":"1.2.3"}}}' \
  >"$fixture/taskboi-mcp/package-lock.json"
printf 'binary fixture\n' >"$fixture/taskboi-mcp/src/unknown.png"
git -C "$fixture" add taskboi-mcp
git -C "$fixture" commit -qm "test: add compliance fixture"
python3 "$REPO_ROOT/scripts/generate-compliance-inventory.py" \
  --repo "$fixture" --revision HEAD --output-dir "$test_dir/fixture-evidence" >/dev/null
python3 - "$test_dir/fixture-evidence/oss-compliance-inventory.json" <<'PY'
import json
import sys

inventory = json.load(open(sys.argv[1], encoding="utf-8"))
assert inventory["dependencies"][0]["license_expression"] == "NOASSERTION"
assert inventory["assets"][0]["provenance_status"] == "NOASSERTION"
assert inventory["unknown_license_dependencies"] == inventory["dependencies"]
assert inventory["unknown_provenance_assets"] == inventory["assets"]
PY

# The canonical record is deliberately unapproved and must fail closed.
if python3 "$REPO_ROOT/scripts/check-public-release-approval.py" \
  "$REPO_ROOT/docs/COMPLIANCE_REVIEW.md" \
  --expected-revision "$HEAD_SHA" >"$test_dir/default-output" 2>&1; then
  echo "Canonical public release approval unexpectedly passed" >&2
  exit 1
fi
grep -F "NOT APPROVED" "$test_dir/default-output" >/dev/null

cat >"$test_dir/approved.md" <<EOF
# Public Release Approval

- Approval status: APPROVED
- Named human/legal reviewer: Example Reviewer, Legal
- Review date (YYYY-MM-DD): 2026-07-26
- Source revision: $HEAD_SHA
- Scoped distribution channels: public source repository
- Notices decision: Reviewed for the scoped source
- License texts decision: Reviewed for the scoped source
- Source-offer decision: Not required for the reviewed scope
- Asset provenance attestations: No assets in the reviewed scope
- Vulnerability disposition: Reviewed for the exact source revision
EOF

python3 "$REPO_ROOT/scripts/check-public-release-approval.py" \
  "$test_dir/approved.md" --expected-revision "$HEAD_SHA"

wrong_sha="0000000000000000000000000000000000000000"
if python3 "$REPO_ROOT/scripts/check-public-release-approval.py" \
  "$test_dir/approved.md" --expected-revision "$wrong_sha" >/dev/null 2>&1; then
  echo "Approval validator accepted a record for a different source revision" >&2
  exit 1
fi

echo "Public-source compliance evidence and approval gate checks passed."
