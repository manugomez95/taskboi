#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly CHECKER="$REPO_ROOT/scripts/check-docs-public-config.sh"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/taskboi-docs-config.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

fail() { echo "Documentation public-config regression failed: $*" >&2; exit 1; }

new_fixture() {
  local fixture="$1"
  mkdir -p "$fixture/config" "$fixture/assets/icons"
  cp "$REPO_ROOT/README.md" "$fixture/README.md"
  cp "$REPO_ROOT/config/public.example.json" "$fixture/config/public.example.json"
  printf '%s\n' 'public-config.local.json' > "$fixture/.gitignore"
  cat > "$fixture/pubspec.yaml" <<'EOF'
name: fixture
flutter:
  assets:
    - assets/icons/
EOF
  git -C "$fixture" init -q
  git -C "$fixture" add README.md config/public.example.json .gitignore pubspec.yaml
}

expect_pass() {
  local fixture="$1"
  CHECK_DOCS_REPO_ROOT="$fixture" "$CHECKER" >/dev/null 2>&1 \
    || fail "expected safe fixture to pass: ${fixture##*/}"
}

expect_asset_rejected() {
  local label="$1" asset="$2"
  local fixture="$test_dir/$label"
  new_fixture "$fixture"
  printf '    - %s\n' "$asset" >> "$fixture/pubspec.yaml"
  if CHECK_DOCS_REPO_ROOT="$fixture" "$CHECKER" >/dev/null 2>&1; then
    fail "unsafe Flutter asset was accepted: $label"
  fi
}

expect_pubspec_rejected() {
  local label="$1" pubspec_body="$2"
  local fixture="$test_dir/$label"
  new_fixture "$fixture"
  printf '%s\n' "$pubspec_body" > "$fixture/pubspec.yaml"
  if CHECK_DOCS_REPO_ROOT="$fixture" "$CHECKER" >/dev/null 2>&1; then
    fail "unsafe Flutter pubspec was accepted: $label"
  fi
}

baseline="$test_dir/baseline"
new_fixture "$baseline"
expect_pass "$baseline"

# Public client configuration is intentionally supported and is not treated as
# an arbitrary secret merely because it is a config file.
printf '%s\n' '    - "public-config.local.json"' >> "$baseline/pubspec.yaml"
expect_pass "$baseline"

flow_safe_fixture="$test_dir/flow-safe-public-config"
new_fixture "$flow_safe_fixture"
printf '%s\n' 'name: fixture' \
  '"flutter": {"assets": ["public-config.local.json"]}' \
  > "$flow_safe_fixture/pubspec.yaml"
expect_pass "$flow_safe_fixture"

expect_asset_rejected dot_env '.env'
expect_asset_rejected dot_env_variant '.env.production'
expect_asset_rejected suffix_env 'production.env'
expect_asset_rejected quoted_dot_env '".env.staging"'
expect_asset_rejected quoted_suffix_env "'production.env'"
expect_asset_rejected repository_root '"./"'
expect_asset_rejected broad_assets "'assets/'"

untracked_fixture="$test_dir/untracked-env-in-asset-directory"
new_fixture "$untracked_fixture"
printf '%s\n' 'non-secret test fixture' > "$untracked_fixture/assets/icons/.env"
printf '%s\n' 'non-secret test fixture' > "$untracked_fixture/assets/icons/production.env"
if CHECK_DOCS_REPO_ROOT="$untracked_fixture" "$CHECKER" >/dev/null 2>&1; then
  fail "asset directory containing untracked .env was accepted"
fi

expect_pubspec_rejected flow_dot_env $'name: fixture\nflutter:\n  assets: [.env]'
expect_pubspec_rejected flow_nested_env $'name: fixture\nflutter:\n  assets: [assets/icons/.env]'
expect_pubspec_rejected multiline_flow_dot_env $'name: fixture\nflutter:\n  assets: [\n    .env\n  ]'
expect_pubspec_rejected flow_flutter_mapping $'name: fixture\nflutter: {assets: [.env]}'
expect_pubspec_rejected quoted_flutter_key $'name: fixture\n"flutter":\n  assets: [.env]'
expect_pubspec_rejected quoted_assets_key $'name: fixture\nflutter:\n  "assets": [.env]'
expect_pubspec_rejected invalid_yaml $'name: fixture\nflutter: {assets: [.env]'
expect_pubspec_rejected invalid_assets_shape $'name: fixture\nflutter: {assets: {path: assets/icons/}}'

tracked_fixture="$test_dir/tracked-env-in-asset-directory"
new_fixture "$tracked_fixture"
printf '%s\n' 'non-secret test fixture' > "$tracked_fixture/assets/icons/.env"
git -C "$tracked_fixture" add -f assets/icons/.env
if CHECK_DOCS_REPO_ROOT="$tracked_fixture" "$CHECKER" >/dev/null 2>&1; then
  fail "asset directory containing tracked .env was accepted"
fi

ignored_fixture="$test_dir/ignored-env-in-asset-directory"
new_fixture "$ignored_fixture"
printf '%s\n' 'assets/icons/.env' >> "$ignored_fixture/.gitignore"
printf '%s\n' 'non-secret test fixture' > "$ignored_fixture/assets/icons/.env"
if CHECK_DOCS_REPO_ROOT="$ignored_fixture" "$CHECKER" >/dev/null 2>&1; then
  fail "asset directory containing ignored .env was accepted"
fi

unrelated_fixture="$test_dir/unrelated-env"
new_fixture "$unrelated_fixture"
printf '%s\n' 'non-secret test fixture' > "$unrelated_fixture/production.env"
git -C "$unrelated_fixture" add -f production.env
expect_pass "$unrelated_fixture"

echo "Documentation public-config regression checks passed."
