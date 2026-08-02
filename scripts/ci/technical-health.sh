#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly FLUTTER_REVISION="924134a44c189315be2148659913dda1671cbe99"
readonly DENO_VERSION="2.9.3"

fail() { echo "Technical health check failed: $*" >&2; exit 1; }

require_pinned_flutter() {
  command -v flutter >/dev/null 2>&1 || fail "Flutter is not on PATH"

  local flutter_bin flutter_root actual_revision
  flutter_bin="$(command -v flutter)"
  flutter_root="$(cd "$(dirname "$flutter_bin")/.." && pwd -P)"
  actual_revision="$(git -C "$flutter_root" rev-parse HEAD 2>/dev/null || true)"
  [[ "$actual_revision" == "$FLUTTER_REVISION" ]] \
    || fail "Flutter must be repository-approved revision $FLUTTER_REVISION (found ${actual_revision:-unknown})"
}

require_pinned_deno() {
  command -v deno >/dev/null 2>&1 || fail "Deno is not on PATH"

  local actual_version
  actual_version="$(deno --version | awk 'NR == 1 { print $2 }')"
  [[ "$actual_version" == "$DENO_VERSION" ]] \
    || fail "Deno must be repository-approved version $DENO_VERSION (found ${actual_version:-unknown})"
}

run_component() {
  local component="$1"
  case "$component" in
    flutter-dependencies)
      require_pinned_flutter
      flutter pub get --enforce-lockfile
      ;;
    flutter-generated)
      require_pinned_flutter
      dart run build_runner build --delete-conflicting-outputs
      "$REPO_ROOT/scripts/ci/check-generated-output.sh"
      ;;
    flutter-format)
      require_pinned_flutter
      dart format --output=none --set-exit-if-changed lib test integration_test
      ;;
    flutter-analyze)
      require_pinned_flutter
      flutter analyze
      ;;
    flutter-test)
      require_pinned_flutter
      (
        config_file="$(mktemp "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/taskboi-public-config.XXXXXX.json")"
        trap 'rm -f "$config_file"' EXIT
        printf '%s\n' '{"PUBLIC_SUPABASE_URL":"https://example.invalid","PUBLIC_SUPABASE_ANON_KEY":"inert-ci-value"}' > "$config_file"
        flutter test --dart-define-from-file="$config_file"
      )
      ;;
    task-engine)
      require_pinned_flutter
      (
        cd "$REPO_ROOT/packages/taskboi_task_engine"
        trap 'rm -f pubspec.lock' EXIT
        dart pub get
        dart format --output=none --set-exit-if-changed lib test
        dart analyze
        dart test
      )
      ;;
    backend-migrations)
      "$REPO_ROOT/scripts/ci/check-migrations.sh"
      ;;
    backend-check)
      require_pinned_deno
      deno task check
      ;;
    backend-test)
      require_pinned_deno
      deno task test
      ;;
    secret-scan)
      "$REPO_ROOT/scripts/ci/secret-scan.sh" history
      ;;
    workflows)
      "$REPO_ROOT/scripts/ci/test-workflows.sh"
      ;;
    *)
      fail "unknown component '$component'"
      ;;
  esac
}

cd "$REPO_ROOT"

if (( $# > 0 )); then
  for component in "$@"; do
    run_component "$component"
  done
else
  readonly COMPONENTS=(
    flutter-dependencies
    flutter-generated
    flutter-format
    flutter-analyze
    flutter-test
    task-engine
    backend-migrations
    backend-check
    backend-test
    secret-scan
    workflows
  )
  for component in "${COMPONENTS[@]}"; do
    echo "==> $component"
    run_component "$component"
  done
fi
