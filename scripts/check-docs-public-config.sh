#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="${CHECK_DOCS_REPO_ROOT:-$(git rev-parse --show-toplevel)}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS=()
while IFS= read -r -d '' doc; do
  DOCS+=("$doc")
done < <(
  find "$REPO_ROOT" \
    -path '*/.git' -prune -o \
    -path '*/node_modules' -prune -o \
    \( -name '*.md' -o -name '*.template' \) -type f -print0
)
readonly DOCS

if grep -En 'cp[[:space:]]+\.env\.example[[:space:]]+\.env|(into|in|use|uses|using)[[:space:]]+`?\.env`?|(^|[^A-Z_])SUPABASE_(URL|ANON_KEY)([^A-Z_]|$)' "${DOCS[@]}"; then
  echo "Documentation check failed: obsolete Flutter configuration guidance found." >&2
  exit 1
fi

if [[ -e "$REPO_ROOT/.env.example" ]]; then
  echo "Documentation check failed: obsolete .env.example is tracked." >&2
  exit 1
fi

grep -Fq 'cp config/public.example.json public-config.local.json' "$REPO_ROOT/README.md"
grep -Fq 'flutter run --dart-define-from-file=public-config.local.json' "$REPO_ROOT/README.md"
grep -Fq '"PUBLIC_SUPABASE_URL"' "$REPO_ROOT/config/public.example.json"
grep -Fq '"PUBLIC_SUPABASE_ANON_KEY"' "$REPO_ROOT/config/public.example.json"
grep -Fxq 'public-config.local.json' "$REPO_ROOT/.gitignore"

# A declared asset directory can silently package a developer's local .env
# file. Parse YAML structurally with Ruby's standard-library Psych, then inspect
# only the declared entries and directories.
if ! command -v ruby >/dev/null 2>&1; then
  echo "Documentation check failed: Ruby 2.6 or newer with Psych 3.1 or newer is required to parse pubspec.yaml." >&2
  exit 1
fi

asset_list="$(mktemp "${TMPDIR:-/tmp}/taskboi-pubspec-assets.XXXXXX")"
trap 'rm -f "$asset_list"' EXIT
if ! ruby "$SCRIPT_DIR/parse-flutter-assets.rb" "$REPO_ROOT/pubspec.yaml" > "$asset_list"; then
  exit 1
fi

while IFS= read -r -d '' asset; do
  normalized="$asset"
  normalized="${normalized#./}"
  normalized="${normalized%/}"

  if [[ -z "$normalized" || "$normalized" == "." || "$normalized" == "assets" \
    || "$normalized" == /* || "/$normalized/" == *"/../"* \
    || "$normalized" =~ (^|/)\.env($|\.) || "$normalized" =~ (^|/)[^/]+\.env$ ]]; then
    echo "Documentation check failed: Flutter assets may package local environment files." >&2
    exit 1
  fi

  # Flutter recursively bundles directory entries. Limit the repository query
  # to each declared directory so unrelated configuration is not prohibited.
  if [[ "$asset" == */ ]] && {
      git -C "$REPO_ROOT" ls-files --cached -- "$normalized"
      git -C "$REPO_ROOT" ls-files --others --exclude-standard -- "$normalized"
      git -C "$REPO_ROOT" ls-files --others --ignored --exclude-standard -- "$normalized"
    } | grep -Eq '(^|/)(\.env($|\.)|[^/]+\.env$)'; then
    echo "Documentation check failed: Flutter asset directory contains an environment file: $asset" >&2
    exit 1
  fi
done < "$asset_list"

echo "Documentation public-config check passed."
