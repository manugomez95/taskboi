#!/usr/bin/env bash
set -euo pipefail

readonly REQUIRED_GITLEAKS_VERSION="8.30.1"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
readonly GITLEAKS_BIN="${GITLEAKS_BIN:-}"

usage() {
  echo "Usage: $0 history | artifacts <path> [<path> ...]" >&2
}

if [[ -z "$REPO_ROOT" ]]; then
  echo "Secret scan gate failed: run from inside the repository." >&2
  exit 2
fi
if [[ -z "$GITLEAKS_BIN" || ! -x "$GITLEAKS_BIN" ]]; then
  echo "Secret scan gate failed closed: a verified scanner path is required." >&2
  exit 2
fi

installed_version="$("$GITLEAKS_BIN" version 2>/dev/null | tr -d '[:space:]' | sed 's/^v//')"
if [[ "$installed_version" != "$REQUIRED_GITLEAKS_VERSION" ]]; then
  echo "Secret scan gate failed closed: expected gitleaks ${REQUIRED_GITLEAKS_VERSION}; found a different version." >&2
  exit 2
fi

scan_log="$(mktemp "${TMPDIR:-/tmp}/taskboi-gitleaks.XXXXXX")"
chmod 600 "$scan_log"
trap 'rm -f "$scan_log"' EXIT

common_args=(--config "$REPO_ROOT/.gitleaks.toml" --gitleaks-ignore-path "$REPO_ROOT/.gitleaksignore" --redact=100 --no-banner --no-color --log-level error --max-decode-depth 3 --max-archive-depth 3)
case "${1:-}" in
  history)
    [[ "$#" -eq 1 ]] || { usage; exit 2; }
    if ! "$GITLEAKS_BIN" git "${common_args[@]}" --log-opts="--all" "$REPO_ROOT" >"$scan_log" 2>&1; then
      echo "Secret scan gate failed: a finding or scanner error occurred in full Git history; details are withheld to avoid disclosing values." >&2
      exit 1
    fi
    echo "Full-history secret scan passed (values suppressed)."
    ;;
  artifacts)
    shift
    [[ "$#" -gt 0 ]] || { usage; exit 2; }
    for target in "$@"; do
      [[ -e "$target" ]] || {
        echo "Release-artifact secret scan failed closed: a requested artifact does not exist." >&2
        exit 2
      }
      if ! "$GITLEAKS_BIN" dir "${common_args[@]}" "$target" >"$scan_log" 2>&1; then
        echo "Release-artifact secret scan failed: a finding or scanner error occurred; details are withheld to avoid disclosing values." >&2
        exit 1
      fi
    done
    echo "Release-artifact secret scan passed (values suppressed)."
    ;;
  *)
    usage
    exit 2
    ;;
esac
