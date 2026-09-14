#!/usr/bin/env bash
set -euo pipefail

# @file launch.sh
# @brief Build, test, run, stop, and inspect the OrganizeItAll iOS app.
# @description
#   Provides a command-line launcher around xcodebuild and simctl.
#
#   Interactive actions use fzf when an action or simulator has not
#   been supplied explicitly.
#
#   Usage:
#     ./scripts/launch.sh \
#       [menu|run|stop|build|test|devices|xcode|help] \
#       [simulator UUID]


# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

readonly ROOT="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

readonly PROJECT="$ROOT/OrganizeItAll.xcodeproj"
readonly SCHEME="OrganizeItAll"
readonly CONFIGURATION="Debug"
readonly DERIVED_DATA="$ROOT/DerivedData"

readonly BUNDLE_ID="com.moyarich.OrganizeItAll"

readonly GENERIC_DESTINATION="generic/platform=iOS Simulator"


# -----------------------------------------------------------------------------
# Runtime state
# -----------------------------------------------------------------------------

ACTION="${1:-menu}"
DEVICE="${2:-}"
DESTINATION="$GENERIC_DESTINATION"


# -----------------------------------------------------------------------------
# General helpers
# -----------------------------------------------------------------------------

# @section General helpers

# @description Print command usage information.
# @noargs
# @stdout Usage information.
usage() {
  cat <<'USAGE'
Usage:
  ./scripts/launch.sh [action] [simulator UUID]

Actions:
  menu       Choose an action interactively with fzf. Default.
  run        Build, install, and launch the app.
  stop       Stop the app on one or all booted simulators.
  build      Build for a generic iOS Simulator.
  test       Run tests on a selected simulator.
  devices    List available simulators.
  xcode      Open the Xcode project.
  help       Show this help.

Arguments:
  simulator UUID
      Optional for run, test, and stop.

Examples:
  ./scripts/launch.sh
  ./scripts/launch.sh run
  ./scripts/launch.sh run 00000000-0000-0000-0000-000000000000
  ./scripts/launch.sh test
  ./scripts/launch.sh build
  ./scripts/launch.sh stop
  ./scripts/launch.sh devices
USAGE
}


# @description Print an error message and exit.
# @arg $1 string Error message.
# @arg $2 integer Optional exit status. Defaults to 1.
# @stderr Error message.
die() {
  local message="$1"
  local status="${2:-1}"

  echo "$message" >&2
  exit "$status"
}


# @description Present an interactive fzf chooser.
# @arg $1 string Prompt displayed by fzf.
# @stdin Newline-delimited choices.
# @stdout Selected row.
choose() {
  local prompt="$1"

  command -v fzf >/dev/null 2>&1 ||
    die 'fzf is required for interactive selection. Install it with: brew install fzf'

  fzf \
    --height=40% \
    --reverse \
    --border \
    --prompt="$prompt"
}


# @description Validate the requested launcher action.
# @noargs
# @exitcode 0 The action is supported.
# @exitcode 2 The action is unknown.
validate_action() {
  case "$ACTION" in
    help | --help | -h)
      usage
      exit 0
      ;;

    menu | run | stop | build | test | devices | xcode)
      ;;

    *)
      usage >&2
      exit 2
      ;;
  esac
}


# -----------------------------------------------------------------------------
# Xcode
# -----------------------------------------------------------------------------

# @section Xcode

# @description
#   Select a full Xcode developer directory for this process.
#
#   An existing DEVELOPER_DIR is respected when it points to a usable
#   Xcode installation. Otherwise xcode-select is checked, followed by
#   the standard /Applications/Xcode.app location.
#
# @noargs
# @set DEVELOPER_DIR string Active Xcode developer directory.
# @exitcode 0 A usable Xcode installation was found.
configure_xcode() {
  local selected

  if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    [[ -x "$DEVELOPER_DIR/usr/bin/simctl" ]] ||
      die "DEVELOPER_DIR does not point to a full Xcode installation: $DEVELOPER_DIR"

    return 0
  fi

  selected="$(xcode-select -p 2>/dev/null || true)"

  if [[ -x "$selected/usr/bin/simctl" ]]; then
    export DEVELOPER_DIR="$selected"
    return 0
  fi

  if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    return 0
  fi

  die \
    'Full Xcode is required. Install Xcode and an iOS simulator runtime, then try again.'
}


# @description Open the OrganizeItAll Xcode project.
# @noargs
open_project() {
  open "$PROJECT"
}


# -----------------------------------------------------------------------------
# Interactive menu
# -----------------------------------------------------------------------------

# @section Interactive menu

# @description Ask the user which launcher action to perform.
# @noargs
# @set ACTION string Selected launcher action.
select_action() {
  local row

  row="$(
    {
      printf '%s\n' \
        'run — Build and launch app' \
        'stop — Close app on booted simulators' \
        'build — Build for Simulator' \
        'test — Run tests' \
        'devices — List simulators' \
        'xcode — Open project'
    } |
      choose 'OrganizeItAll > '
  )" || exit 0

  ACTION="${row%% *}"
}


# -----------------------------------------------------------------------------
# Simulator helpers
# -----------------------------------------------------------------------------

# @section Simulator helpers

# @description
#   List available iOS simulators and include the associated runtime
#   beside each device.
#
# @noargs
# @stdout Available iOS Simulator rows.
list_ios_simulators() {
  xcrun simctl list devices available |
    awk '
      /^-- / {
        ios = ($0 ~ /^-- iOS /)
        runtime = $0
      }

      ios && /\([0-9A-F-]+\)/ {
        print $0 " " runtime
      }
    '
}


# @description Extract a simulator UUID from a simctl device row.
# @arg $1 string simctl device row.
# @stdout Simulator UUID.
extract_device_id() {
  printf '%s\n' "$1" |
    sed -nE 's/.*\(([0-9A-F-]{36})\).*/\1/p'
}


# @description Determine whether a simulator is currently booted.
# @arg $1 string Simulator UUID.
# @exitcode 0 Simulator is booted.
# @exitcode 1 Simulator is not booted.
is_device_booted() {
  local device="$1"
  local booted

  booted="$(xcrun simctl list devices booted)"

  grep -Fq "($device)" <<<"$booted"
}


# @description
#   Verify that a simulator UUID belongs to an available iOS Simulator.
#
# @arg $1 string Simulator UUID.
# @arg $2 string Newline-delimited available simulator rows.
# @exitcode 0 Simulator is available.
validate_device() {
  local device="$1"
  local devices="$2"

  grep -Fq "($device)" <<<"$devices" ||
    die "Unavailable iOS simulator: $device"
}


# @description
#   Select an iOS Simulator interactively when DEVICE was not supplied.
#
# @arg $1 string Newline-delimited available simulator rows.
# @set DEVICE string Selected simulator UUID.
select_device() {
  local devices="$1"
  local row

  if [[ -n "$DEVICE" ]]; then
    return 0
  fi

  row="$(
    printf '%s\n' "$devices" |
      choose 'Simulator > '
  )" || exit 0

  DEVICE="$(extract_device_id "$row")"

  [[ -n "$DEVICE" ]] ||
    die 'Could not determine the selected simulator UUID.'
}


# @description
#   Boot the selected simulator if necessary, open Simulator.app,
#   and wait until the device has finished booting.
#
# @arg $1 string Simulator UUID.
# @exitcode 0 Simulator is ready.
ensure_simulator_ready() {
  local device="$1"
  local simulator_app="$DEVELOPER_DIR/Applications/Simulator.app"

  if ! is_device_booted "$device"; then
    xcrun simctl boot "$device"
  fi

  open "$simulator_app" \
    --args \
    -CurrentDeviceUDID "$device"

  xcrun simctl bootstatus "$device" -b
}


# @description
#   Select or validate an iOS Simulator and prepare the xcodebuild
#   destination string.
#
# @noargs
# @set DEVICE string Selected or validated simulator UUID.
# @set DESTINATION string xcodebuild destination.
prepare_simulator_destination() {
  local devices

  devices="$(list_ios_simulators)"

  [[ -n "$devices" ]] ||
    die \
      'No iOS simulators are installed. Add an iOS runtime in Xcode Settings > Components.'

  select_device "$devices"
  validate_device "$DEVICE" "$devices"
  ensure_simulator_ready "$DEVICE"

  DESTINATION="platform=iOS Simulator,id=$DEVICE"
}


# -----------------------------------------------------------------------------
# Stop
# -----------------------------------------------------------------------------

# @section Stop

# @description
#   Stop OrganizeItAll on the requested simulator.
#
#   When no DEVICE is supplied, the app is terminated on every
#   currently booted simulator.
#
# @noargs
# @stdout Status for each simulator.
stop_app() {
  local booted
  local id
  local output

  booted="$(
    xcrun simctl list devices booted |
      sed -nE 's/.*\(([0-9A-F-]{36})\).*/\1/p'
  )"

  if [[ -n "$DEVICE" ]]; then
    grep -Fxq "$DEVICE" <<<"$booted" ||
      die 'That simulator is not booted.'

    booted="$DEVICE"
  fi

  if [[ -z "$booted" ]]; then
    echo 'No booted simulators. The app is already stopped.'
    return 0
  fi

  while IFS= read -r id; do
    if output="$(
      xcrun simctl terminate \
        "$id" \
        "$BUNDLE_ID" \
        2>&1
    )"; then
      echo "Closed OrganizeItAll on $id."

    elif [[
      "$output" == *"not running"* ||
      "$output" == *"found nothing to terminate"*
    ]]; then
      echo "OrganizeItAll is already stopped on $id."

    else
      echo "$output" >&2
      return 1
    fi
  done <<<"$booted"
}


# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------

# @section Build

# @description Run xcodebuild with the project's standard configuration.
# @arg $1 string xcodebuild action, such as build or test.
# @arg $2 string xcodebuild destination.
# @exitcode 0 xcodebuild completed successfully.
run_xcodebuild() {
  local build_action="$1"
  local destination="$2"

  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -destination "$destination" \
    CODE_SIGNING_ALLOWED=NO \
    "$build_action"
}


# -----------------------------------------------------------------------------
# Launch
# -----------------------------------------------------------------------------

# @section Launch

# @description
#   Install the previously built OrganizeItAll.app on DEVICE and launch it.
#
# @noargs
# @exitcode 0 Application was installed and launched.
launch_app() {
  local app

  app="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/OrganizeItAll.app"

  [[ -d "$app" ]] ||
    die "Built app not found: $app"

  xcrun simctl install \
    "$DEVICE" \
    "$app"

  xcrun simctl launch \
    --terminate-running-process \
    "$DEVICE" \
    "$BUNDLE_ID"
}


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

# @section Program entry point

# @description Dispatch the requested launcher action.
# @noargs
main() {
  local build_action="build"

  validate_action
  configure_xcode

  if [[ "$ACTION" == "menu" ]]; then
    select_action
  fi

  case "$ACTION" in
    xcode)
      open_project
      ;;

    devices)
      xcrun simctl list devices available
      ;;

    stop)
      stop_app
      ;;

    run | test)
      prepare_simulator_destination

      if [[ "$ACTION" == "test" ]]; then
        build_action="test"
      fi

      run_xcodebuild \
        "$build_action" \
        "$DESTINATION"

      if [[ "$ACTION" == "run" ]]; then
        launch_app
      fi
      ;;

    build)
      run_xcodebuild \
        "$build_action" \
        "$DESTINATION"
      ;;
  esac
}


main