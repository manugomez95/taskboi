#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly VALIDATOR="$REPO_ROOT/scripts/ci/validate-task-engine-consumer.rb"
readonly FIXTURE_ROOT="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/taskboi-task-engine-consumer.XXXXXX")"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

fail() { echo "Task engine consumer contract test failed: $*" >&2; exit 1; }

write_fixture() {
  local name="$1" content="$2"
  mkdir -p "$FIXTURE_ROOT/$name"
  printf '%s\n' "$content" > "$FIXTURE_ROOT/$name/pubspec.yaml"
}

expect_invalid() {
  local name="$1"
  if "$VALIDATOR" "$FIXTURE_ROOT/$name/pubspec.yaml" >/dev/null 2>&1; then
    fail "invalid fixture unexpectedly passed: $name"
  fi
}

readonly VALID=$'name: contract_consumer\nenvironment:\n  sdk: ^3.6.2\ndependencies:\n  taskboi_task_engine:\n    git:\n      url: https://github.com/manugomez95/taskboi.git\n      ref: b0e7d4b06ef22e547e3e044616dc85ab6a11e04f\n      path: packages/taskboi_task_engine'
write_fixture valid "$VALID"
"$VALIDATOR" "$FIXTURE_ROOT/valid/pubspec.yaml" >/dev/null

write_fixture malformed $'name: broken\ndependencies: ['
write_fixture absent $'name: absent\ndependencies:\n  collection: any'
write_fixture local_path $'name: bad\ndependencies:\n  taskboi_task_engine:\n    path: ../taskboi_task_engine'
write_fixture scalar_git $'name: bad\ndependencies:\n  taskboi_task_engine:\n    git: https://github.com/manugomez95/taskboi.git'
write_fixture missing_url $'name: bad\ndependencies:\n  taskboi_task_engine:\n    git:\n      ref: b0e7d4b06ef22e547e3e044616dc85ab6a11e04f\n      path: packages/taskboi_task_engine'
write_fixture missing_ref $'name: bad\ndependencies:\n  taskboi_task_engine:\n    git:\n      url: https://github.com/manugomez95/taskboi.git\n      path: packages/taskboi_task_engine'
write_fixture nonscalar_ref "${VALID/ref: b0e7d4b06ef22e547e3e044616dc85ab6a11e04f/ref: 1234567890123456789012345678901234567890}"
write_fixture branch "${VALID/b0e7d4b06ef22e547e3e044616dc85ab6a11e04f/main}"
write_fixture tag "${VALID/b0e7d4b06ef22e547e3e044616dc85ab6a11e04f/v0.1.0}"
write_fixture short_sha "${VALID/b0e7d4b06ef22e547e3e044616dc85ab6a11e04f/b0e7d4b}"
write_fixture invalid_ref "${VALID/b0e7d4b06ef22e547e3e044616dc85ab6a11e04f/zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz}"
write_fixture ssh_url "${VALID/https:\/\/github.com\/manugomez95\/taskboi.git/git@github.com:manugomez95\/taskboi.git}"
write_fixture noncanonical_url "${VALID/https:\/\/github.com\/manugomez95\/taskboi.git/https:\/\/github.com\/manugomez95\/taskboi}"
write_fixture missing_path $'name: bad\ndependencies:\n  taskboi_task_engine:\n    git:\n      url: https://github.com/manugomez95/taskboi.git\n      ref: b0e7d4b06ef22e547e3e044616dc85ab6a11e04f'
write_fixture wrong_path "${VALID/packages\/taskboi_task_engine/packages\/other}"
write_fixture extra_field "${VALID/path: packages\/taskboi_task_engine/path: packages\/taskboi_task_engine\n      hosted: nowhere}"
write_fixture dev_dependency "${VALID/dependencies:/dev_dependencies:}"
write_fixture override "${VALID/dependencies:/dependency_overrides:}"
write_fixture duplicate $'name: bad\ndependencies:\n  taskboi_task_engine:\n    git:\n      url: https://github.com/manugomez95/taskboi.git\n      ref: b0e7d4b06ef22e547e3e044616dc85ab6a11e04f\n      ref: a0e7d4b06ef22e547e3e044616dc85ab6a11e04f\n      path: packages/taskboi_task_engine'
write_fixture multiple_documents "$VALID"$'\n---\nname: ignored_second_document'
write_fixture alias $'name: bad\ndependencies:\n  taskboi_task_engine: &engine\n    git:\n      url: https://github.com/manugomez95/taskboi.git\n      ref: b0e7d4b06ef22e547e3e044616dc85ab6a11e04f\n      path: packages/taskboi_task_engine\ndev_dependencies:\n  taskboi_task_engine: *engine'

for fixture in malformed absent local_path scalar_git missing_url missing_ref nonscalar_ref branch tag short_sha invalid_ref ssh_url noncanonical_url missing_path wrong_path extra_field dev_dependency override duplicate multiple_documents alias; do
  expect_invalid "$fixture"
done

(
  cd "$FIXTURE_ROOT/valid"
  dart pub get
)

echo "Task engine consumer contract tests passed."
