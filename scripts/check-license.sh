#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly APACHE_2_SHA256="cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30"

actual_sha256="$(shasum -a 256 "$REPO_ROOT/LICENSE" | awk '{print $1}')"
if [[ "$actual_sha256" != "$APACHE_2_SHA256" ]]; then
  echo "License check failed: LICENSE is not the exact official Apache 2.0 text." >&2
  exit 1
fi

echo "Apache-2.0 repository license check passed."
