#!/usr/bin/env bash
set -euo pipefail

project_root=$(git rev-parse --show-toplevel)
cd "$project_root"

migrations=()
while IFS= read -r migration; do
  migrations+=("$migration")
done < <(find supabase/migrations -maxdepth 1 -type f -name '*.sql' -print | LC_ALL=C sort)
if ((${#migrations[@]} == 0)); then
  echo "No migrations found" >&2
  exit 1
fi

previous=0
for migration in "${migrations[@]}"; do
  name=${migration##*/}
  if [[ ! $name =~ ^([0-9]{3})_[a-z0-9_]+\.sql$ ]]; then
    echo "Invalid migration name: $migration" >&2
    exit 1
  fi
  number=$((10#${BASH_REMATCH[1]}))
  if ((number == previous)); then
    echo "Duplicate migration number: ${BASH_REMATCH[1]}" >&2
    exit 1
  fi
  if ((number <= previous)); then
    echo "Migrations are not strictly ordered at $migration" >&2
    exit 1
  fi
  if ! LC_ALL=C grep -q '[^[:space:]]' "$migration"; then
    echo "Empty migration: $migration" >&2
    exit 1
  fi
  previous=$number
done

scripts/ci/check-remote-imports.sh supabase/functions deno.json

echo "Validated ${#migrations[@]} ordered, uniquely numbered migrations."
