#!/bin/bash
set -euo pipefail
SCRIPTS="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  help|--help|-h) echo 'Usage: ./scripts/menu.sh — interactive app and App Store actions'; exit 0 ;;
  '') ;;
  *) echo 'Usage: ./scripts/menu.sh' >&2; exit 2 ;;
esac
"$SCRIPTS/setup.sh"

if ! command -v fzf >/dev/null 2>&1; then
  echo 'Install fzf with: brew install fzf' >&2
  exit 1
fi
CHOICE="$(printf '%s\n' \
  'run — Build and launch in Simulator' \
  'stop — Close app on booted simulators' \
  'build — Build for Simulator' \
  'test — Run simulator tests' \
  'models — Run model tests on Mac' \
  'devices — List simulators' \
  'xcode — Open project in Xcode' \
  'check — Check App Store configuration' \
  'export — Build a signed App Store IPA' \
  'upload — Build and upload to App Store Connect' \
  'quit — Exit menu (app keeps running)' | fzf --height=50% --reverse --border \
    --prompt='OrganizeItAll > ' --header='Select an action · Escape to cancel')" || {
  STATUS=$?
  case "$STATUS" in 1|130) exit 0 ;; *) exit "$STATUS" ;; esac
}
case "${CHOICE%% *}" in
  models) exec "$SCRIPTS/test.sh" ;;
  run|stop|build|test|devices|xcode) exec "$SCRIPTS/launch.sh" "${CHOICE%% *}" ;;
  check|export|upload) exec "$SCRIPTS/publish.sh" "${CHOICE%% *}" ;;
  quit) exit 0 ;;
  *) echo 'Unknown menu action.' >&2; exit 2 ;;
esac
