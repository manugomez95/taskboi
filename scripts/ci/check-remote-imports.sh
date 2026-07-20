#!/usr/bin/env bash
set -euo pipefail

scan_roots=("${@:-supabase/functions}")
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

files=()
for scan_root in "${scan_roots[@]}"; do
  if [[ -f "$scan_root" ]]; then
    files+=("$scan_root")
  elif [[ -d "$scan_root" ]]; then
    while IFS= read -r file; do
      files+=("$file")
    done < <(find "$scan_root" -type f \( \
      -name '*.ts' -o -name '*.tsx' -o -name '*.mts' -o -name '*.cts' -o \
      -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' -o \
      -name 'deno.json' -o -name 'deno.jsonc' -o -name 'import_map.json' -o \
      -name 'import-map.json' \) -print | LC_ALL=C sort)
  else
    echo "Deno import scan input does not exist: $scan_root" >&2
    exit 1
  fi
done

if ((${#files[@]} == 0)); then
  echo "No Deno source or import-map/config files found in the scan inputs" >&2
  exit 1
fi

ruby "$script_dir/check-remote-imports.rb" "${files[@]}"

echo "Deno remote imports are pinned to exact versions."
