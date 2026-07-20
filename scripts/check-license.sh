#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly APACHE_2_SHA256="cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30"

actual_sha256="$(shasum -a 256 "$REPO_ROOT/LICENSE" | awk '{print $1}')"
if [[ "$actual_sha256" != "$APACHE_2_SHA256" ]]; then
  echo "License check failed: LICENSE is not the exact official Apache 2.0 text." >&2
  exit 1
fi

node - "$REPO_ROOT" <<'NODE'
const fs = require('node:fs');
const path = require('node:path');

const root = process.argv[2];
for (const relative of [
  'taskboi-mcp/package.json',
  'taskboi-mcp/package-lock.json',
]) {
  const document = JSON.parse(fs.readFileSync(path.join(root, relative), 'utf8'));
  const license = relative.endsWith('package-lock.json')
    ? document.packages?.['']?.license
    : document.license;
  if (license !== 'Apache-2.0') {
    throw new Error(`${relative} must use the SPDX identifier Apache-2.0`);
  }
}
NODE

echo "Apache-2.0 license and package metadata check passed."
