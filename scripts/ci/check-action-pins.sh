#!/usr/bin/env bash
set -euo pipefail

readonly workflows_root="${1:-.github/workflows}"
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$workflows_root" ]]; then
  echo "Workflow directory does not exist: $workflows_root" >&2
  exit 1
fi

workflows=()
while IFS= read -r workflow; do
  workflows+=("$workflow")
done < <(find "$workflows_root" -type f \( -name '*.yml' -o -name '*.yaml' \) -print | LC_ALL=C sort)

if ((${#workflows[@]} == 0)); then
  echo "No GitHub Actions workflows found under $workflows_root" >&2
  exit 1
fi

ruby "$script_dir/check-action-pins.rb" "${workflows[@]}"

echo "External GitHub Actions are pinned to full commit SHAs."
