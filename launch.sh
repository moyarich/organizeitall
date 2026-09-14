#!/bin/bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-menu}"
DEVICE="${2:-}"
usage() {
  echo 'Usage: ./launch.sh [menu|run|build|test|devices|xcode|help] [simulator UUID]'
}
case "$ACTION" in
  help|--help|-h) usage; exit 0 ;;
  menu|run|build|test|devices|xcode) ;;
  *) usage >&2; exit 2 ;;
esac

# Select full Xcode for this process without changing the Mac's global setting.
if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  SELECTED="$(xcode-select -p 2>/dev/null || true)"
  if [[ -x "$SELECTED/usr/bin/simctl" ]]; then
    export DEVELOPER_DIR="$SELECTED"
  elif [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  else
    echo 'Full Xcode is required. Install Xcode and an iOS simulator runtime, then try again.' >&2
    exit 1
  fi
fi
choose() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo 'Install fzf with: brew install fzf. Or use a command and simulator UUID from --help.' >&2
    exit 1
  fi
  fzf --height=40% --reverse --border --prompt="$1"
}
if [[ "$ACTION" == menu ]]; then
  ACTION="$(printf '%s\n' 'run — Build and launch app' 'build — Build for Simulator' 'test — Run tests' 'devices — List simulators' 'xcode — Open project' | choose 'OrganizeItAll > ')" || exit 0
  ACTION="${ACTION%% *}"
fi
case "$ACTION" in
  xcode) open "$ROOT/OrganizeItAll.xcodeproj"; exit ;;
  devices) xcrun simctl list devices available; exit ;;
esac

DESTINATION='generic/platform=iOS Simulator'
if [[ "$ACTION" == run || "$ACTION" == test ]]; then
  DEVICES="$(xcrun simctl list devices available | awk '/^-- / {ios=($0 ~ /^-- iOS /); runtime=$0} ios && /\([0-9A-F-]+\)/ {print $0 " " runtime}')"
  if [[ -z "$DEVICES" ]]; then
    echo 'No iOS simulators are installed. Add an iOS runtime in Xcode Settings > Components.' >&2
    exit 1
  fi
  if [[ -z "$DEVICE" ]]; then
    ROW="$(printf '%s\n' "$DEVICES" | choose 'Simulator > ')" || exit 0
    DEVICE="$(printf '%s\n' "$ROW" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
  fi
  if ! printf '%s\n' "$DEVICES" | grep -Fq "($DEVICE)"; then
    echo "Unavailable iOS simulator: $DEVICE" >&2
    exit 1
  fi
  DESTINATION="platform=iOS Simulator,id=$DEVICE"
  if ! xcrun simctl list devices booted | grep -Fq "($DEVICE)"; then
    xcrun simctl boot "$DEVICE"
  fi
  open -a "$DEVELOPER_DIR/Applications/Simulator.app" --args -CurrentDeviceUDID "$DEVICE"
  xcrun simctl bootstatus "$DEVICE" -b
fi
BUILD_ACTION=build
[[ "$ACTION" != test ]] || BUILD_ACTION=test
xcodebuild -project "$ROOT/OrganizeItAll.xcodeproj" \
  -scheme OrganizeItAll -configuration Debug \
  -derivedDataPath "$ROOT/DerivedData" -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED=NO "$BUILD_ACTION"
if [[ "$ACTION" == run ]]; then
  APP="$ROOT/DerivedData/Build/Products/Debug-iphonesimulator/OrganizeItAll.app"
  xcrun simctl install "$DEVICE" "$APP"
  xcrun simctl launch --terminate-running-process "$DEVICE" com.moyarich.OrganizeItAll
fi
