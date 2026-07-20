#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/taskboi-scan-test.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

mkdir -p "$test_dir/bin" "$test_dir/artifact"
cat >"$test_dir/bin/gitleaks" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == version ]]; then echo "${FAKE_VERSION:-8.30.1}"; exit 0; fi
printf '%s\n' "$@" >"$FAKE_ARGS"
if [[ "${FAKE_FAIL:-0}" == 1 ]]; then echo "DO-NOT-PRINT-THIS-VALUE"; exit 1; fi
EOF
chmod +x "$test_dir/bin/gitleaks"

export GITLEAKS_BIN="$test_dir/bin/gitleaks" FAKE_ARGS="$test_dir/args"
"$REPO_ROOT/scripts/scan-secrets.sh" history >/dev/null
grep -Fx -- '--redact=100' "$FAKE_ARGS" >/dev/null
grep -Fx -- '--log-opts=--all' "$FAKE_ARGS" >/dev/null

"$REPO_ROOT/scripts/scan-secrets.sh" artifacts "$test_dir/artifact" >/dev/null
grep -Fx -- '--max-archive-depth' "$FAKE_ARGS" >/dev/null

if output="$(FAKE_FAIL=1 "$REPO_ROOT/scripts/scan-secrets.sh" artifacts "$test_dir/artifact" 2>&1)"; then
  echo "Expected finding to fail the gate" >&2
  exit 1
fi
if [[ "$output" == *DO-NOT-PRINT-THIS-VALUE* ]]; then
  echo "Scanner output was not suppressed" >&2
  exit 1
fi

if FAKE_VERSION=0.0.0 "$REPO_ROOT/scripts/scan-secrets.sh" history >/dev/null 2>&1; then
  echo "Expected a mismatched scanner version to fail closed" >&2
  exit 1
fi

echo "Secret scan wrapper checks passed."
