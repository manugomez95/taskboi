#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly CI="${CI_WORKFLOW_FILE:-$REPO_ROOT/.github/workflows/ci.yml}"
readonly RELEASE="$REPO_ROOT/.github/workflows/release-candidate.yml"
readonly NETLIFY="$REPO_ROOT/netlify.toml"
readonly GITLEAKS_CONFIG="$REPO_ROOT/.gitleaks.toml"
readonly GITLEAKS_IGNORE="$REPO_ROOT/.gitleaksignore"

fail() { echo "Workflow regression check failed: $*" >&2; exit 1; }

if grep -E '(^|[[:space:]>/=])\.env([[:space:]/]|$)|(^|[^A-Z_])SUPABASE_URL=|(^|[^A-Z_])SUPABASE_ANON_KEY=' "$CI" "$RELEASE" "$NETLIFY" >/dev/null; then
  fail "legacy environment-file or define syntax is present"
fi

grep -F -- 'printf '\''%s\n'\'' '\''{"PUBLIC_SUPABASE_URL":"https://example.invalid","PUBLIC_SUPABASE_ANON_KEY":"inert-ci-value"}'\'' > "$config_file"' "$REPO_ROOT/scripts/ci/technical-health.sh" >/dev/null \
  || fail "canonical Flutter test config is missing or does not contain exactly the PUBLIC keys"
grep -F -- 'printf '\''%s\n'\'' '\''{"PUBLIC_SUPABASE_URL":"https://example.invalid","PUBLIC_SUPABASE_ANON_KEY":"inert-release-value"}'\'' > "$config_file"' "$RELEASE" >/dev/null \
  || fail "release temporary config is missing or does not contain exactly the PUBLIC keys"

grep -F 'scripts/ci/technical-health.sh secret-scan' "$CI" >/dev/null \
  || fail "CI does not invoke the canonical secret-scan component"
grep -F 'dart run build_runner build --delete-conflicting-outputs' "$REPO_ROOT/scripts/ci/technical-health.sh" >/dev/null \
  || fail "canonical command does not regenerate committed Flutter sources"
grep -F '"$REPO_ROOT/scripts/ci/check-generated-output.sh"' "$REPO_ROOT/scripts/ci/technical-health.sh" >/dev/null \
  || fail "canonical command does not reject generated tree drift"
if grep -Eiq 'taskboi-mcp|cache-dependency-path:.*package-lock|npm (ci|pack|publish)' "$CI" "$RELEASE"; then
  fail "core workflows must not reference or package the separated MCP project"
fi
if ! ruby -rpsych -e '
  begin
    workflow = Psych.safe_load(File.read(ARGV.fetch(0)), aliases: false)
    job = workflow.fetch("jobs").fetch("workflow-regression")
    steps = job.fetch("steps")
    unless steps.is_a?(Array) && steps.any? { |step| step.is_a?(Hash) && step["run"] == "scripts/ci/technical-health.sh workflows" }
      exit 1
    end
  rescue Psych::Exception, KeyError, TypeError
    exit 1
  end
' "$CI"; then
  fail "CI workflow-regression job must invoke the canonical workflows component"
fi
grep -F 'scripts/ci/secret-scan.sh history' "$RELEASE" >/dev/null \
  || fail "release does not scan full history"
grep -F 'GITLEAKS_BIN="$tool_dir/gitleaks" "$REPO_ROOT/scripts/scan-secrets.sh" "$@"' "$REPO_ROOT/scripts/ci/secret-scan.sh" >/dev/null \
  || fail "CI secret scan does not pass the verified scanner path explicitly"
release_checkout_line="$(grep -n -F 'actions/checkout@' "$RELEASE" | cut -d: -f1)"
release_fetch_line="$(grep -n -F 'fetch-depth: 0' "$RELEASE" | cut -d: -f1)"
release_history_line="$(grep -n -F 'scripts/ci/secret-scan.sh history' "$RELEASE" | cut -d: -f1)"
[[ -n "$release_fetch_line" && "$release_checkout_line" -lt "$release_fetch_line" && "$release_fetch_line" -lt "$release_history_line" ]] \
  || fail "release history scan must use a full checkout"
grep -F 'scripts/ci/secret-scan.sh artifacts release' "$RELEASE" >/dev/null \
  || fail "release artifacts are not scanned"

scan_line="$(grep -n -F 'scripts/ci/secret-scan.sh artifacts release' "$RELEASE" | cut -d: -f1)"
inventory_line="$(grep -n -F 'scripts/generate-compliance-inventory.py' "$RELEASE" | cut -d: -f1)"
verify_line="$(grep -n -F 'scripts/verify-release-candidate.py' "$RELEASE" | cut -d: -f1)"
validate_line="$(grep -n -m1 -F 'scripts/validate-spdx.py' "$RELEASE" | cut -d: -f1)"
checksum_line="$(grep -n -F 'sha256sum --check --strict SHA256SUMS' "$RELEASE" | cut -d: -f1)"
attest_line="$(grep -n -F 'actions/attest-build-provenance@' "$RELEASE" | cut -d: -f1)"
upload_line="$(grep -n -F 'actions/upload-artifact@' "$RELEASE" | cut -d: -f1)"
[[ -n "$inventory_line" && -n "$validate_line" && -n "$verify_line" && -n "$checksum_line" && "$inventory_line" -lt "$validate_line" && "$validate_line" -lt "$verify_line" && "$verify_line" -lt "$checksum_line" && "$checksum_line" -lt "$scan_line" && "$scan_line" -lt "$attest_line" && "$scan_line" -lt "$upload_line" ]] \
  || fail "SPDX and candidate verification, checksums, and artifact scan must precede attestation and upload"
if grep -F 'check-public-release-approval.py' "$RELEASE" >/dev/null; then
  fail "internal release-candidate builds must not require public-release approval"
fi

grep -F -- 'flutter build web --release --dart-define-from-file="$PUBLIC_CONFIG_FILE"' "$NETLIFY" >/dev/null \
  || fail "Netlify does not use the validated PUBLIC config file"
grep -F './scripts/scan-secrets.sh artifacts build/web' "$NETLIFY" >/dev/null \
  || fail "Netlify artifact scan was removed"

expected_gitleaks_fingerprints="$(cat <<'EOF'
0265074fe4c88dfdecf042eb24e2fc34bc710cc6:macos/Podfile.lock:generic-api-key:144
0265074fe4c88dfdecf042eb24e2fc34bc710cc6:macos/Podfile.lock:generic-api-key:153
9be40d47b4861ffdaa106588a003d1ac6ad1429e:macos/Podfile.lock:generic-api-key:87
9be40d47b4861ffdaa106588a003d1ac6ad1429e:macos/Podfile.lock:generic-api-key:93
acaececed0f18b87a85ce3bfeb433c09f324350b:macos/Podfile.lock:generic-api-key:144
acaececed0f18b87a85ce3bfeb433c09f324350b:macos/Podfile.lock:generic-api-key:153
00068f6759b1041a66581c251c8a6154f4608e60:macos/Podfile.lock:generic-api-key:87
00068f6759b1041a66581c251c8a6154f4608e60:macos/Podfile.lock:generic-api-key:93
EOF
)"
actual_gitleaks_fingerprints="$(grep -vE '^[[:space:]]*(#|$)' "$GITLEAKS_IGNORE")"
[[ "$actual_gitleaks_fingerprints" == "$expected_gitleaks_fingerprints" ]] \
  || fail "Gitleaks history exceptions differ from the literal reviewed fingerprint/path/rule set"
if grep -Eiq '(^|:)[^:]*workers?(/|:)|(^|/)worker(s)?/' "$GITLEAKS_IGNORE"; then
  fail "Worker source paths must never appear in Gitleaks history exceptions"
fi
grep -F -- '--gitleaks-ignore-path "$REPO_ROOT/.gitleaksignore"' "$REPO_ROOT/scripts/scan-secrets.sh" >/dev/null \
  || fail "secret scan does not fail closed through the reviewed config"
if grep -Eq 'paths|regexes|commits|stopwords' "$GITLEAKS_CONFIG"; then
  fail "Gitleaks history exceptions are broader than exact fingerprints"
fi

"$REPO_ROOT/scripts/ci/check-action-pins.sh" "$REPO_ROOT/.github/workflows"

if awk '/^jobs:$/ { in_jobs=1; next } in_jobs && /^  dependency-review:$/ { found=1 } END { exit !found }' "$CI"; then
  fail "private internal CI must not define a dependency-review job"
fi

flutter_job="$(awk '
  /^  flutter:$/ { in_flutter=1 }
  in_flutter && /^  [A-Za-z0-9_-]+:$/ && $0 != "  flutter:" { exit }
  in_flutter { print }
' "$CI")"
locked_line="$(printf '%s\n' "$flutter_job" | grep -n -F 'scripts/ci/technical-health.sh flutter-dependencies' | cut -d: -f1)"
generate_line="$(printf '%s\n' "$flutter_job" | grep -n -F 'scripts/ci/technical-health.sh flutter-generated' | cut -d: -f1)"
format_line="$(printf '%s\n' "$flutter_job" | grep -n -F 'scripts/ci/technical-health.sh flutter-format' | cut -d: -f1)"
analyze_line="$(printf '%s\n' "$flutter_job" | grep -n -F 'scripts/ci/technical-health.sh flutter-analyze' | cut -d: -f1)"
test_line="$(printf '%s\n' "$flutter_job" | grep -n -F 'scripts/ci/technical-health.sh flutter-test' | cut -d: -f1)"
task_engine_line="$(printf '%s\n' "$flutter_job" | grep -n -E 'scripts/ci/technical-health\.sh task-engine$' | cut -d: -f1 || true)"
task_engine_contract_line="$(printf '%s\n' "$flutter_job" | grep -n -F 'scripts/ci/technical-health.sh task-engine-consumer-contract' | cut -d: -f1 || true)"
[[ -n "$locked_line" && "$locked_line" -lt "$generate_line" && \
  "$generate_line" -lt "$format_line" && "$format_line" -lt "$analyze_line" && \
  "$analyze_line" -lt "$test_line" && "$test_line" -lt "$task_engine_line" && \
  "$task_engine_line" -lt "$task_engine_contract_line" ]] \
  || fail "Flutter technical-health components are missing or out of order"

if ! ruby -rpsych -e '
  begin
    workflow = Psych.safe_load(File.read(ARGV.fetch(0)), aliases: false)
    steps = workflow.fetch("jobs").fetch("flutter").fetch("steps")
    commands = steps.map { |step| step["run"] if step.is_a?(Hash) }.compact
    engine = commands.index("scripts/ci/technical-health.sh task-engine")
    contract = commands.index("scripts/ci/technical-health.sh task-engine-consumer-contract")
    exit 1 unless engine && contract && contract == engine + 1
  rescue Psych::Exception, KeyError, TypeError
    exit 1
  end
' "$CI"; then
  fail "Flutter job must run task-engine-consumer-contract immediately after task-engine"
fi

for component in backend-migrations backend-check backend-test; do
  grep -F "scripts/ci/technical-health.sh $component" "$CI" >/dev/null \
    || fail "CI does not invoke canonical component $component"
done

fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/taskboi-ci-regression.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    fail "negative regression fixture unexpectedly passed: $*"
  fi
}

remote_failure() {
  local name="$1" file="$2" content="$3"
  local case_dir="$fixture_root/import-$name"
  mkdir -p "$case_dir"
  printf '%s\n' "$content" > "$case_dir/$file"
  expect_failure "$REPO_ROOT/scripts/ci/check-remote-imports.sh" "$case_dir"
}

remote_failure major major.tsx 'import "https://esm.sh/pkg@2";'
remote_failure minor deno.json '{"imports":{"pkg":"https://esm.sh/pkg@2.3"}}'
remote_failure unversioned import_map.json '{"imports":{"std/":"https://deno.land/std/assert/"}}'
remote_failure latest bypass.mjs 'export * from "https://deno.land/std@latest/assert/mod.ts";'
remote_failure query-semver bypass.mjs 'import "https://esm.sh/pkg@latest/mod.ts?fallback=@1.2.3";'
remote_failure escaped deno.json '{"imports":{"pkg":"https:\/\/esm.sh\/pkg@2"}}'
remote_failure generic worker.cts 'const pkg = import("https://example.com/pkg/mod.ts");'
remote_failure npm worker.js 'export {x} from "npm:package@^2.3.4";'
remote_failure semver-v-prefix worker.mjs 'import "https://esm.sh/pkg@v1.2.3";'
remote_failure semver-leading-zero worker.mjs 'import "https://esm.sh/pkg@01.2.3";'
remote_failure semver-prerelease-leading-zero worker.mjs 'import "https://esm.sh/pkg@1.2.3-01";'
remote_failure template-latest worker.mjs 'const pkg = import(`https://esm.sh/pkg@latest`);'
remote_failure template-interpolation worker.mjs 'const pkg = import(`https://esm.sh/${packageName}@1.2.3`);'
remote_failure template-interpolated-scheme worker.mjs 'const pkg = import(`${scheme}://esm.sh/pkg@1.2.3`);'
remote_failure template-interpolation-after-comment worker.mjs $'const pkg = import(/* remote package */ `https://esm.sh/${packageName}@1.2.3`);'
remote_failure template-interpolation-after-line-comment worker.mjs $'const pkg = import(// remote package\n  `https://esm.sh/${packageName}@1.2.3`);'
remote_failure malformed deno.json '{"imports":'
remote_failure jsonc deno.jsonc '{"imports": { /* rejected fail-closed */ "pkg": "https://esm.sh/pkg@2.3.4" }}'

valid_remote_imports="$fixture_root/import-valid"
mkdir -p "$valid_remote_imports"
printf '%s\n' 'const pkg = import(`https://esm.sh/pkg@1.2.3`);' > "$valid_remote_imports/static-template.mjs"
"$REPO_ROOT/scripts/ci/check-remote-imports.sh" "$valid_remote_imports" >/dev/null

action_failure() {
  local name="$1" content="$2"
  local case_dir="$fixture_root/action-$name"
  mkdir -p "$case_dir"
  printf '%s\n' "$content" > "$case_dir/workflow.yml"
  expect_failure "$REPO_ROOT/scripts/ci/check-action-pins.sh" "$case_dir"
}

action_failure tag $'jobs:\n  test:\n    steps:\n      - uses: actions/checkout@v4'
action_failure reusable $'jobs:\n  call:\n    uses: owner/reusable/.github/workflows/ci.yml@main'
action_failure short $'jobs:\n  test:\n    steps:\n      - uses: "owner/action@1234567890abcdef"'
action_failure expression $'jobs:\n  test:\n    steps:\n      - uses: owner/action@${{ github.ref }}'
action_failure quoted-key $'jobs:\n  test:\n    steps:\n      - "uses": owner/action@main'
action_failure flow '{jobs: {test: {steps: [{uses: owner/action@main}]}}}'
action_failure docker $'jobs:\n  test:\n    steps:\n      - uses: docker://alpine:latest'
action_failure malformed $'jobs:\n  test: [}'
action_failure duplicate-uses $'jobs:\n  test:\n    steps:\n      - uses: owner/action@main\n        uses: ./local-action'

valid_actions="$fixture_root/action-valid"
mkdir -p "$valid_actions"
printf '%s\n' '{jobs: {test: {steps: [{"uses": owner/action@0123456789abcdef0123456789abcdef01234567}, {uses: ./local-action}]}}}' > "$valid_actions/workflow.yaml"
"$REPO_ROOT/scripts/ci/check-action-pins.sh" "$valid_actions" >/dev/null

echo "Workflow regression checks passed."
