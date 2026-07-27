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

release="$REPO_ROOT/.github/workflows/release-candidate.yml"
if grep -Eiq 'taskboi-mcp|npm (ci|pack|publish)|wrangler|deploy' "$release"; then
  echo "Core release candidate contains MCP packaging or deployment logic" >&2
  exit 1
fi

echo "Core release preflight checks passed."
