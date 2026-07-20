#!/usr/bin/env bash
set -euo pipefail

readonly GITLEAKS_VERSION="8.30.1"
readonly REPO_ROOT="$(git rev-parse --show-toplevel)"

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)
    readonly GITLEAKS_PLATFORM="linux_x64"
    readonly GITLEAKS_SHA256="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"
    ;;
  Darwin-arm64)
    readonly GITLEAKS_PLATFORM="darwin_arm64"
    readonly GITLEAKS_SHA256="b40ab0ae55c505963e365f271a8d3846efbc170aa17f2607f13df610a9aeb6a5"
    ;;
  Darwin-x86_64)
    readonly GITLEAKS_PLATFORM="darwin_x64"
    readonly GITLEAKS_SHA256="dfe101a4db2255fc85120ac7f3d25e4342c3c20cf749f2c20a18081af1952709"
    ;;
  *)
    echo "Gitleaks bootstrap failed closed: unsupported runner platform." >&2
    exit 2
    ;;
esac

tool_dir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/taskboi-gitleaks.XXXXXX")"
trap 'rm -rf "$tool_dir"' EXIT

archive="$tool_dir/gitleaks.tar.gz"
curl --fail --silent --show-error --location \
  "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_${GITLEAKS_PLATFORM}.tar.gz" \
  --output "$archive"
actual_sha256="$(sha256sum "$archive" | awk '{print $1}')"
if [[ "$actual_sha256" != "$GITLEAKS_SHA256" ]]; then
  echo "Gitleaks bootstrap failed closed: archive checksum verification failed." >&2
  exit 1
fi
tar -xzf "$archive" -C "$tool_dir" gitleaks
chmod 755 "$tool_dir/gitleaks"

GITLEAKS_BIN="$tool_dir/gitleaks" "$REPO_ROOT/scripts/scan-secrets.sh" "$@"
