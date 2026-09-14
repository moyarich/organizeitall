#!/usr/bin/env bash
set -euo pipefail

# @file publish.sh
# @brief Validate, archive, export, and upload OrganizeItAll to App Store Connect.
# @description
#   Provides the release workflow for OrganizeItAll.
#
#   Configuration is loaded from the repository's trusted local `.env` file.
#
#   Actions:
#     check   Validate local publishing configuration.
#     export  Archive and export a signed IPA.
#     upload  Archive and upload the build to App Store Connect.
#
#   Usage:
#     ./scripts/publish.sh [check|export|upload]


# -----------------------------------------------------------------------------
# Project configuration
# -----------------------------------------------------------------------------

readonly ROOT="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

readonly ENV_FILE="$ROOT/.env"

readonly PROJECT="$ROOT/OrganizeItAll.xcodeproj"
readonly SCHEME="OrganizeItAll"
readonly CONFIGURATION="Release"

readonly BUILD_ROOT="$ROOT/build/app-store"
readonly ARCHIVE_NAME="OrganizeItAll.xcarchive"

readonly IOS_DESTINATION="generic/platform=iOS"
readonly DEFAULT_XCODE="/Applications/Xcode.app/Contents/Developer"

ACTION="${1:-check}"
OUT=""

AUTH_ARGS=()


# -----------------------------------------------------------------------------
# General helpers
# -----------------------------------------------------------------------------

# @section General helpers

# @description Print command usage.
# @noargs
# @stdout Usage information.
usage() {
  cat <<'USAGE'
Usage:
  ./scripts/publish.sh [check|export|upload]

Actions:
  check
      Validate the local Xcode and App Store Connect configuration.

  export
      Create a signed App Store archive and export an IPA locally.

  upload
      Create a signed App Store archive and upload it to App Store Connect.

Examples:
  ./scripts/publish.sh
  ./scripts/publish.sh check
  ./scripts/publish.sh export
  ./scripts/publish.sh upload
USAGE
}


# @description Print an error message and exit.
# @arg $1 string Error message.
# @arg $2 integer Optional exit status. Defaults to 1.
# @stderr Error message.
fail() {
  local message="$1"
  local status="${2:-1}"

  echo "Error: $message" >&2
  exit "$status"
}


# @description Validate command-line arguments.
# @arg $@ string Script arguments.
# @exitcode 0 Arguments are valid.
# @exitcode 2 Arguments are invalid.
validate_cli() {
  [[ $# -le 1 ]] ||
    fail 'Expected one action only.' 2

  case "$ACTION" in
    help | --help | -h)
      usage
      exit 0
      ;;

    check | export | upload)
      ;;

    *)
      usage >&2
      exit 2
      ;;
  esac
}


# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------

# @section Environment

# @description
#   Load publishing configuration from the trusted local `.env` file.
#
#   This script intentionally sources `.env`, so the file must remain
#   local and trusted. Never replace it with downloaded or untrusted input.
#
# @noargs
load_environment() {
  [[ -f "$ENV_FILE" ]] ||
    fail 'Copy .env.example to .env and fill in your Apple account settings.'

  # This is intentionally a trusted local shell configuration.
  # shellcheck source=/dev/null
  source "$ENV_FILE"
}


# @description Require a non-empty environment variable.
# @arg $1 string Variable name.
# @exitcode 0 Variable is set.
require_variable() {
  local name="$1"

  [[ -n "${!name:-}" ]] ||
    fail "Set $name in .env."
}


# @description Require all publishing environment variables.
# @noargs
require_configuration() {
  local name

  for name in \
    APPLE_TEAM_ID \
    ASC_KEY_ID \
    ASC_ISSUER_ID \
    ASC_KEY_PATH \
    APP_VERSION \
    BUILD_NUMBER
  do
    require_variable "$name"
  done
}


# @description
#   Resolve ASC_KEY_PATH to an absolute path.
#
#   Absolute paths are preserved. Paths beginning with ~/ are resolved
#   relative to HOME. All other paths are resolved relative to the
#   repository root.
#
# @noargs
# @set ASC_KEY_PATH string Absolute path to the App Store Connect key.
resolve_key_path() {
  case "$ASC_KEY_PATH" in
    /*)
      ;;

    "~/"*)
      ASC_KEY_PATH="$HOME/${ASC_KEY_PATH#\~/}"
      ;;

    *)
      ASC_KEY_PATH="$ROOT/$ASC_KEY_PATH"
      ;;
  esac
}


# @description Validate App Store Connect and version configuration.
# @noargs
validate_configuration() {
  require_configuration
  resolve_key_path

  [[ "$APPLE_TEAM_ID" =~ ^[A-Z0-9]{10}$ ]] ||
    fail 'APPLE_TEAM_ID must be a 10-character Apple team ID.'

  [[ "$ASC_KEY_ID" =~ ^[A-Z0-9]{10}$ ]] ||
    fail 'ASC_KEY_ID must be a 10-character App Store Connect key ID.'

  [[ "$ASC_ISSUER_ID" =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$ ]] ||
    fail 'ASC_ISSUER_ID must be a valid issuer UUID.'

  [[ "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    fail 'APP_VERSION must use major.minor.patch format, for example 1.2.0.'

  [[ "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]] ||
    fail 'BUILD_NUMBER must be a positive integer and increase for each upload.'

  [[ "$ASC_KEY_PATH" == *.p8 ]] ||
    fail 'ASC_KEY_PATH must point to an App Store Connect .p8 key.'

  [[ -f "$ASC_KEY_PATH" ]] ||
    fail "App Store Connect key does not exist: $ASC_KEY_PATH"

  [[ -r "$ASC_KEY_PATH" ]] ||
    fail "App Store Connect key is not readable: $ASC_KEY_PATH"

  [[ -d "$PROJECT" ]] ||
    fail "Xcode project not found: $PROJECT"
}


# -----------------------------------------------------------------------------
# Xcode
# -----------------------------------------------------------------------------

# @section Xcode

# @description
#   Configure DEVELOPER_DIR for a full Xcode installation.
#
#   Priority:
#     1. DEVELOPER_DIR from .env or the calling environment.
#     2. The currently selected xcode-select developer directory.
#     3. /Applications/Xcode.app/Contents/Developer.
#
# @noargs
# @set DEVELOPER_DIR string Full Xcode developer directory.
configure_xcode() {
  local selected=""

  if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    validate_xcode_directory "$DEVELOPER_DIR"
    export DEVELOPER_DIR
    return
  fi

  selected="$(xcode-select -p 2>/dev/null || true)"

  if is_full_xcode "$selected"; then
    export DEVELOPER_DIR="$selected"
    return
  fi

  if is_full_xcode "$DEFAULT_XCODE"; then
    export DEVELOPER_DIR="$DEFAULT_XCODE"
    return
  fi

  fail 'Install full Xcode or set DEVELOPER_DIR in .env.'
}


# @description Determine whether a developer directory contains full Xcode.
# @arg $1 string Developer directory.
# @exitcode 0 Directory contains the required Xcode tools and iOS platform.
# @exitcode 1 Directory is not a usable full Xcode installation.
is_full_xcode() {
  local developer_dir="$1"

  [[ -n "$developer_dir" ]] &&
    [[ -x "$developer_dir/usr/bin/xcodebuild" ]] &&
    [[ -d "$developer_dir/Platforms/iPhoneOS.platform" ]]
}


# @description Validate an explicitly configured Xcode developer directory.
# @arg $1 string Developer directory.
validate_xcode_directory() {
  local developer_dir="$1"

  is_full_xcode "$developer_dir" ||
    fail "DEVELOPER_DIR does not point to a full Xcode installation: $developer_dir"
}


# @description Verify that xcodebuild can be located through xcrun.
# @noargs
validate_xcode_tools() {
  command -v xcrun >/dev/null 2>&1 ||
    fail 'xcrun was not found. Install Xcode.'

  xcrun --find xcodebuild >/dev/null 2>&1 ||
    fail 'xcodebuild was not found. Install full Xcode or correct DEVELOPER_DIR.'
}


# -----------------------------------------------------------------------------
# App Store Connect authentication
# -----------------------------------------------------------------------------

# @section App Store Connect authentication

# @description Build reusable xcodebuild authentication arguments.
# @noargs
# @set AUTH_ARGS array xcodebuild App Store Connect authentication arguments.
configure_authentication() {
  AUTH_ARGS=(
    -allowProvisioningUpdates
    -authenticationKeyPath "$ASC_KEY_PATH"
    -authenticationKeyID "$ASC_KEY_ID"
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
  )
}


# -----------------------------------------------------------------------------
# Build output
# -----------------------------------------------------------------------------

# @section Build output

# @description Create a unique directory for this publishing operation.
# @noargs
# @set OUT string Absolute publishing output directory.
create_output_directory() {
  local timestamp

  timestamp="$(date '+%Y%m%d-%H%M%S')"
  OUT="$BUILD_ROOT/${timestamp}-$$"

  mkdir -p "$OUT"
}


# @description Return the archive path for this publishing operation.
# @noargs
# @stdout Absolute .xcarchive path.
archive_path() {
  printf '%s/%s\n' "$OUT" "$ARCHIVE_NAME"
}


# -----------------------------------------------------------------------------
# Archive
# -----------------------------------------------------------------------------

# @section Archive

# @description Create a signed App Store archive.
# @noargs
archive_app() {
  echo
  echo '==> Creating App Store archive'
  echo "    Version: $APP_VERSION"
  echo "    Build:   $BUILD_NUMBER"
  echo

  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "$IOS_DESTINATION" \
    -archivePath "$(archive_path)" \
    "${AUTH_ARGS[@]}" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    MARKETING_VERSION="$APP_VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    archive
}


# -----------------------------------------------------------------------------
# Export configuration
# -----------------------------------------------------------------------------

# @section Export configuration

# @description Determine the xcodebuild export destination.
# @noargs
# @stdout Either export or upload.
export_destination() {
  case "$ACTION" in
    export)
      printf '%s\n' 'export'
      ;;

    upload)
      printf '%s\n' 'upload'
      ;;

    *)
      fail "No export destination exists for action: $ACTION"
      ;;
  esac
}


# @description Generate ExportOptions.plist for App Store distribution.
# @noargs
# @stdout Nothing.
write_export_options() {
  local destination
  local plist

  destination="$(export_destination)"
  plist="$OUT/ExportOptions.plist"

  cat >"$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>

    <key>destination</key>
    <string>$destination</string>

    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>

    <key>signingStyle</key>
    <string>automatic</string>

    <key>manageAppVersionAndBuildNumber</key>
    <false/>

    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
PLIST

  plutil -lint "$plist" >/dev/null ||
    fail "Generated invalid ExportOptions.plist: $plist"
}


# -----------------------------------------------------------------------------
# Export / Upload
# -----------------------------------------------------------------------------

# @section Export and upload

# @description
#   Export the archive according to ExportOptions.plist.
#
#   For the export action this produces local App Store artifacts.
#   For the upload action xcodebuild submits the archive to
#   App Store Connect.
#
# @noargs
export_archive() {
  echo
  echo "==> ${ACTION^} App Store archive"
  echo

  xcodebuild \
    -exportArchive \
    -archivePath "$(archive_path)" \
    -exportOptionsPlist "$OUT/ExportOptions.plist" \
    -exportPath "$OUT/export" \
    "${AUTH_ARGS[@]}"
}


# -----------------------------------------------------------------------------
# Check
# -----------------------------------------------------------------------------

# @section Configuration check

# @description Print the validated local publishing configuration.
# @noargs
show_configuration_summary() {
  echo
  echo 'Local publishing configuration is valid.'
  echo
  echo "Xcode:"
  xcodebuild -version

  echo
  echo "Project:       $PROJECT"
  echo "Scheme:        $SCHEME"
  echo "Team ID:       $APPLE_TEAM_ID"
  echo "Version:       $APP_VERSION"
  echo "Build:         $BUILD_NUMBER"
  echo "ASC Key ID:    $ASC_KEY_ID"
  echo "ASC Key Path:  $ASC_KEY_PATH"

  echo
  echo 'Apple account access, provisioning, and signing have not been verified.'
}


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

# @section Program entry point

# @description Execute the requested publishing workflow.
# @arg $@ string Script command-line arguments.
main() {
  validate_cli "$@"

  load_environment
  validate_configuration

  configure_xcode
  validate_xcode_tools
  configure_authentication

  case "$ACTION" in
    check)
      show_configuration_summary
      ;;

    export | upload)
      create_output_directory
      archive_app
      write_export_options
      export_archive

      echo
      echo "Artifacts: $OUT"

      if [[ "$ACTION" == "upload" ]]; then
        echo
        echo 'Upload completed.'
        echo 'Wait for App Store Connect processing, then select the build for submission.'
      fi
      ;;
  esac
}


main "$@"