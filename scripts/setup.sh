#!/usr/bin/env bash
set -euo pipefail

# @file setup.sh
# @brief Configure the local OrganizeItAll development environment.
# @description
#   Installs direnv when necessary, enables native .env loading,
#   creates the project's local .env, and authorizes it with direnv.
#
#   The script is idempotent. When everything is already configured,
#   a successful run produces no output.


# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

readonly ROOT="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

readonly ENV_FILE="$ROOT/.env"
readonly ENV_EXAMPLE="$ROOT/.env.example"

readonly DEFAULT_DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"


# -----------------------------------------------------------------------------
# General helpers
# -----------------------------------------------------------------------------

# @description Print an error message and exit.
# @arg $1 string Error message.
# @stderr Error message.
fail() {
  echo "Error: $1" >&2
  exit 1
}


# -----------------------------------------------------------------------------
# direnv
# -----------------------------------------------------------------------------

# @section direnv

# @description Install direnv when it is not already available.
# @noargs
ensure_direnv() {
  command -v direnv >/dev/null 2>&1 &&
    return 0

  command -v brew >/dev/null 2>&1 ||
    fail \
      'Homebrew is required to install direnv. Install it from https://brew.sh and rerun ./scripts/setup.sh.'

  echo 'Installing direnv...'
  brew install direnv
}


# @description
#   Configure user-level direnv settings.
#
#   Enables:
#     - Native .env discovery.
#     - Hidden environment-variable diffs.
#
#   Existing direnv.toml settings are preserved.
#
# @noargs
configure_direnv() {
  local config

  config="$(
    python3 - <<'PY'
import os
import re
from pathlib import Path

xdg_config = Path(
    os.environ.get(
        "XDG_CONFIG_HOME",
        str(Path.home() / ".config"),
    )
)

config_dir = Path(
    os.environ.get(
        "DIRENV_CONFIG",
        str(xdg_config / "direnv"),
    )
)

config = config_dir / "direnv.toml"
config.parent.mkdir(parents=True, exist_ok=True)

original = config.read_text() if config.exists() else ""
text = original

settings = {
    "load_dotenv": "true",
    "hide_env_diff": "true",
}

section = re.search(
    r"(?ms)^\[global\][^\n]*\n(?P<body>.*?)(?=^\[|\Z)",
    text,
)

if section:
    body = section.group("body")

    for key, value in settings.items():
        pattern = rf"(?m)^\s*{re.escape(key)}\s*=.*$"
        replacement = f"{key} = {value}"

        if re.search(pattern, body):
            body = re.sub(pattern, replacement, body)
        else:
            if body and not body.endswith("\n"):
                body += "\n"

            body += replacement + "\n"

    text = (
        text[:section.start("body")]
        + body
        + text[section.end("body"):]
    )

else:
    if text and not text.endswith("\n"):
        text += "\n"

    if text:
        text += "\n"

    text += "[global]\n"

    for key, value in settings.items():
        text += f"{key} = {value}\n"

if text != original:
    config.write_text(text)
    print(config)
PY
  )"

  if [[ -n "$config" ]]; then
    echo "Updated direnv settings: $config"
  fi
}


# -----------------------------------------------------------------------------
# Project environment
# -----------------------------------------------------------------------------

# @section Project environment

# @description
#   Create and configure the project's local .env file.
#
#   The file is copied from .env.example when missing. DEVELOPER_DIR is added
#   only when not already configured. File permissions are restricted to 600.
#
# @noargs
configure_env_file() {
  local changes
  local created=false
  local developer_dir_added=false

  changes="$(
    ENV_FILE="$ENV_FILE" \
    ENV_EXAMPLE="$ENV_EXAMPLE" \
    DEFAULT_DEVELOPER_DIR="$DEFAULT_DEVELOPER_DIR" \
      python3 - <<'PY'
import os
import re
import stat
from pathlib import Path

env = Path(os.environ["ENV_FILE"])
example = Path(os.environ["ENV_EXAMPLE"])
developer_dir = os.environ["DEFAULT_DEVELOPER_DIR"]

if not env.exists():
    if not example.is_file():
        raise SystemExit(
            f"Missing environment template: {example}"
        )

    env.write_text(example.read_text())
    print("created")

text = env.read_text()

if not re.search(
    r"(?m)^\s*DEVELOPER_DIR\s*=",
    text,
):
    if text and not text.endswith("\n"):
        text += "\n"

    text += (
        f'DEVELOPER_DIR="{developer_dir}"\n'
    )

    env.write_text(text)
    print("developer-dir")

mode = stat.S_IMODE(env.stat().st_mode)

if mode != 0o600:
    env.chmod(0o600)
PY
  )" || fail 'Unable to configure .env.'

  [[ "$changes" == *"created"* ]] &&
    created=true

  [[ "$changes" == *"developer-dir"* ]] &&
    developer_dir_added=true

  if [[ "$created" == true ]]; then
    echo 'Created .env from .env.example.'

  elif [[ "$developer_dir_added" == true ]]; then
    echo 'Added DEVELOPER_DIR to .env.'
  fi
}


# -----------------------------------------------------------------------------
# Authorization
# -----------------------------------------------------------------------------

# @section Authorization

# @description
#   Authorize the project .env only when direnv cannot currently load it.
#
#
# @noargs
authorize_env_file() {
  direnv exec "$ROOT" true >/dev/null 2>&1 &&
    return 0

  direnv allow "$ENV_FILE" >/dev/null 2>&1 ||
    fail 'Unable to authorize .env with direnv.'

  direnv exec "$ROOT" true >/dev/null 2>&1 ||
    fail 'direnv could not load .env. Check the file for invalid syntax.'
}


# -----------------------------------------------------------------------------
# Shell integration
# -----------------------------------------------------------------------------

# @section Shell integration

# @description
#   Check whether the user's shell configuration contains a direnv hook.
#
#   Instructions are printed only when manual shell setup is still required.
#
# @noargs
check_shell_hook() {
  local shell_name
  local rc_file
  local hook

  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
    zsh)
      rc_file="${ZDOTDIR:-$HOME}/.zshrc"
      hook='eval "$(direnv hook zsh)"'
      ;;

    bash)
      rc_file="$HOME/.bashrc"
      hook='eval "$(direnv hook bash)"'
      ;;

    fish)
      rc_file="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
      hook='direnv hook fish | source'
      ;;

    *)
      return 0
      ;;
  esac

  if [[ -f "$rc_file" ]] &&
    grep -Fq 'direnv hook' "$rc_file"
  then
    return 0
  fi

  cat <<EOF

direnv shell integration is not configured.

Add this to:
  $rc_file

  $hook

Then open a new terminal.
EOF
}


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

# @section Program entry point

# @description Configure the local development environment.
# @noargs
main() {
  ensure_direnv
  configure_direnv
  configure_env_file
  authorize_env_file
  check_shell_hook
}


main "$@"