#!/usr/bin/env bash
set -euo pipefail

readonly GITLEAKS_VERSION="8.30.1"
readonly DOWNLOAD_BASE="${GITLEAKS_DOWNLOAD_BASE:-https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}}"
readonly TOOL_DIR="${TASKBOI_TOOL_DIR:-${TMPDIR:-/tmp}/taskboi-release-tools}"
readonly GITLEAKS_BIN="$TOOL_DIR/gitleaks"

platform="$(uname -s)"
machine="$(uname -m)"
case "$platform:$machine" in
  Darwin:arm64) asset="gitleaks_${GITLEAKS_VERSION}_darwin_arm64.tar.gz"; checksum="b40ab0ae55c505963e365f271a8d3846efbc170aa17f2607f13df610a9aeb6a5" ;;
  Darwin:x86_64) asset="gitleaks_${GITLEAKS_VERSION}_darwin_x64.tar.gz"; checksum="dfe101a4db2255fc85120ac7f3d25e4342c3c20cf749f2c20a18081af1952709" ;;
  Linux:aarch64|Linux:arm64) asset="gitleaks_${GITLEAKS_VERSION}_linux_arm64.tar.gz"; checksum="e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080" ;;
  Linux:x86_64|Linux:amd64) asset="gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"; checksum="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb" ;;
  *) echo "Scanner bootstrap failed closed: unsupported release host platform." >&2; exit 2 ;;
esac

version_of() {
  "$1" version 2>/dev/null | tr -d '[:space:]' | sed 's/^v//'
}

mkdir -p "$TOOL_DIR"
chmod 700 "$TOOL_DIR"
archive="$(mktemp "${TMPDIR:-/tmp}/taskboi-gitleaks.XXXXXX")"
extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/taskboi-gitleaks-extract.XXXXXX")"
trap 'rm -f "$archive"; rm -rf "$extract_dir"' EXIT

curl --fail --silent --show-error --location "$DOWNLOAD_BASE/$asset" --output "$archive"
actual_checksum="$(shasum -a 256 "$archive" | awk '{print $1}')"
if [[ "$actual_checksum" != "$checksum" ]]; then
  echo "Scanner bootstrap failed closed: archive checksum verification failed." >&2
  exit 2
fi
tar -xzf "$archive" -C "$extract_dir" gitleaks
install -m 755 "$extract_dir/gitleaks" "$GITLEAKS_BIN"
if [[ "$(version_of "$GITLEAKS_BIN" || true)" != "$GITLEAKS_VERSION" ]]; then
  rm -f "$GITLEAKS_BIN"
  echo "Scanner bootstrap failed closed: installed scanner version verification failed." >&2
  exit 2
fi

printf '%s\n' "$GITLEAKS_BIN"
