#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/taskboi-preflight-test.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

valid_config="$test_dir/public.json"
printf '%s\n' '{"PUBLIC_SUPABASE_URL":"https://example.invalid","PUBLIC_SUPABASE_ANON_KEY":"inert-public-test-value"}' >"$valid_config"
"$REPO_ROOT/scripts/validate-public-config.sh" "$valid_config" >/dev/null

if output="$("$REPO_ROOT/scripts/validate-public-config.sh" "$test_dir/missing.json" 2>&1)"; then
  echo "Expected missing public config to fail closed" >&2
  exit 1
fi
if [[ "$output" == *inert-public-test-value* ]]; then
  echo "Public config diagnostics exposed a value" >&2
  exit 1
fi

extra_config="$test_dir/extra.json"
printf '%s\n' '{"PUBLIC_SUPABASE_URL":"https://example.invalid","PUBLIC_SUPABASE_ANON_KEY":"inert-public-test-value","PRIVILEGED_SETTING":"do-not-print-this-value"}' >"$extra_config"
if output="$("$REPO_ROOT/scripts/validate-public-config.sh" "$extra_config" 2>&1)"; then
  echo "Expected public config with an extra setting to fail closed" >&2
  exit 1
fi
if [[ "$output" == *do-not-print-this-value* ]]; then
  echo "Public config diagnostics exposed an extra setting value" >&2
  exit 1
fi

mkdir -p "$test_dir/downloads" "$test_dir/tools"
platform="$(uname -s)"
machine="$(uname -m)"
case "$platform:$machine" in
  Darwin:arm64) asset="gitleaks_8.30.1_darwin_arm64.tar.gz" ;;
  Darwin:x86_64) asset="gitleaks_8.30.1_darwin_x64.tar.gz" ;;
  Linux:aarch64|Linux:arm64) asset="gitleaks_8.30.1_linux_arm64.tar.gz" ;;
  Linux:x86_64|Linux:amd64) asset="gitleaks_8.30.1_linux_x64.tar.gz" ;;
  *) asset="unsupported" ;;
esac
printf 'corrupt scanner archive' >"$test_dir/downloads/$asset"
if GITLEAKS_DOWNLOAD_BASE="file://$test_dir/downloads" TASKBOI_TOOL_DIR="$test_dir/tools" \
  "$REPO_ROOT/scripts/bootstrap-gitleaks.sh" >/dev/null 2>&1; then
  echo "Expected scanner bootstrap to reject a checksum mismatch" >&2
  exit 1
fi
if [[ -e "$test_dir/tools/gitleaks" ]]; then
  echo "Scanner bootstrap retained an unverified executable" >&2
  exit 1
fi

deploy="$REPO_ROOT/scripts/deploy.sh"
bootstrap_line="$(grep -n 'bootstrap-gitleaks.sh' "$deploy" | head -n1 | cut -d: -f1)"
config_line="$(grep -n 'validate-public-config.sh' "$deploy" | head -n1 | cut -d: -f1)"
scan_line="$(grep -n 'scan-secrets.sh.*history' "$deploy" | head -n1 | cut -d: -f1)"
checkout_line="$(grep -n 'git checkout main' "$deploy" | head -n1 | cut -d: -f1)"
worker_release_line="$(grep -n '^release_worker$' "$deploy" | cut -d: -f1)"
if ! (( bootstrap_line < config_line && config_line < scan_line && scan_line < checkout_line && config_line < worker_release_line )); then
  echo "Release bootstrap/config/gate sequencing regressed" >&2
  exit 1
fi

worker_build_line="$(grep -n 'npm run build -- --config' "$deploy" | cut -d: -f1)"
worker_artifact_scan_line="$(grep -n -F 'scan-secrets.sh" artifacts "$WORKER_BUILD_DIR"' "$deploy" | cut -d: -f1)"
candidate_upload_line="$(grep -n '"$WRANGLER" versions upload' "$deploy" | cut -d: -f1)"
direct_activation_line="$(grep -n '"$WRANGLER" deploy --keep-vars' "$deploy" | cut -d: -f1)"
traffic_activation_line="$(grep -n '"$WRANGLER" versions deploy' "$deploy" | cut -d: -f1)"
if ! grep -F 'WORKER_BUILD_DIR="$WORKER_DIR/dist"' "$deploy" >/dev/null ||
  [[ -z "$worker_artifact_scan_line" ]] ||
  ! (( worker_build_line < worker_artifact_scan_line &&
       worker_artifact_scan_line < candidate_upload_line &&
       worker_artifact_scan_line < direct_activation_line &&
       worker_artifact_scan_line < traffic_activation_line )); then
  echo "Worker artifact gate must follow the dry-run build and precede upload and activation" >&2
  exit 1
fi

grep -F 'bundle install)' "$deploy" >/dev/null
if grep -E 'bundle install.*\|\||create-dmg.*\|\| true' "$deploy" "$REPO_ROOT/fastlane/Fastfile" >/dev/null; then
  echo "Release path contains a prohibited fail-open" >&2
  exit 1
fi

echo "Release preflight sequencing checks passed."
