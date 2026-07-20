#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
readonly CONFIG_INPUT="${1:-${PUBLIC_CONFIG_FILE:-public-config.local.json}}"

if [[ -z "$REPO_ROOT" ]]; then
  echo "Public config preflight failed: run from inside the repository; values were not inspected in diagnostics." >&2
  exit 2
fi
if [[ "$CONFIG_INPUT" = /* ]]; then CONFIG_PATH="$CONFIG_INPUT"; else CONFIG_PATH="$REPO_ROOT/$CONFIG_INPUT"; fi
if [[ ! -f "$CONFIG_PATH" || ! -r "$CONFIG_PATH" ]]; then
  echo "Public config preflight failed: the required readable regular file is unavailable; values were not printed." >&2
  exit 2
fi

node - "$CONFIG_PATH" <<'NODE'
const fs = require("fs");
try {
  const value = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
  if (!value || Array.isArray(value) || typeof value !== "object") throw new Error();
  const allowedKeys = ["PUBLIC_SUPABASE_ANON_KEY", "PUBLIC_SUPABASE_URL"];
  const actualKeys = Object.keys(value).sort();
  if (actualKeys.length !== allowedKeys.length || actualKeys.some((key, index) => key !== allowedKeys[index])) throw new Error();
  const url = value.PUBLIC_SUPABASE_URL;
  const key = value.PUBLIC_SUPABASE_ANON_KEY;
  if (typeof url !== "string" || typeof key !== "string" || !key.trim()) throw new Error();
  const parsed = new URL(url);
  if (!["http:", "https:"].includes(parsed.protocol) || !parsed.hostname || parsed.username || parsed.password || parsed.hash) throw new Error();
} catch (_) {
  console.error("Public config preflight failed: expected valid public Flutter configuration; values were not printed.");
  process.exit(2);
}
console.log("Public config preflight passed (values suppressed).");
NODE
