#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_XCODE="/Applications/Xcode.app/Contents/Developer"

if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  DEVELOPER_DIR="$(xcode-select -p 2>/dev/null || true)"

  if [[ ! -x "$DEVELOPER_DIR/usr/bin/simctl" ]]; then
    DEVELOPER_DIR="$DEFAULT_XCODE"
  fi

  export DEVELOPER_DIR
fi

if [[ ! -x "$DEVELOPER_DIR/usr/bin/simctl" ]]; then
  echo 'SwiftData tests require full Xcode. Install Xcode or set DEVELOPER_DIR to its Contents/Developer directory.' >&2
  exit 1
fi

exec xcrun swift test \
  --package-path "$ROOT" \
  --scratch-path "$ROOT/.build/xcode-tests" \
  "$@"