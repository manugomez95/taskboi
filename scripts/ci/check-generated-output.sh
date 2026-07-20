#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

tracked_changes="$(git status --porcelain --untracked-files=no)"
untracked_files="$(git ls-files --others --exclude-standard)"

if [[ -n "$tracked_changes" || -n "$untracked_files" ]]; then
  echo "Generated output differs from the checked-out commit." >&2
  if [[ -n "$tracked_changes" ]]; then
    echo "Tracked files changed:" >&2
    git status --short --untracked-files=no >&2
  fi
  if [[ -n "$untracked_files" ]]; then
    echo "Unexpected untracked files:" >&2
    printf '%s\n' "$untracked_files" >&2
  fi
  echo "CI must run this check after generation from an initially clean checkout." >&2
  echo "For local use, commit or stash unrelated work before generating and checking." >&2
  exit 1
fi

echo "Generated output matches the committed tree."
