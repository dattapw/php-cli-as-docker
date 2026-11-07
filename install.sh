#!/bin/sh
# Installer for the dockerized PHP CLI (serversideup/php).
#
# Downloads php.sh from the repo and installs it as ~/.local/bin/php, links
# composer to it, and makes sure ~/.local/bin is on your PATH.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dattapw/php-cli-as-docker/main/install.sh | sh
#   sh install.sh

set -eu

URL="https://raw.githubusercontent.com/dattapw/php-cli-as-docker/main/php.sh"
BIN_DIR="$HOME/.local/bin"

# Download URL to a file using curl or wget
download() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$2" "$1"
  else
    echo "Error: curl or wget is required." >&2
    return 1
  fi
}

mkdir -p "$BIN_DIR"

# 1. Download php.sh into a temp file next to the destination
TMP="$(mktemp "$BIN_DIR/.php.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

echo "Downloading $URL"
if ! download "$URL" "$TMP"; then
  echo "Error: download failed." >&2
  exit 1
fi

# Sanity check: must be a non-empty script, not an HTML error page
if [ ! -s "$TMP" ] || ! head -n 1 "$TMP" | grep -q '^#!'; then
  echo "Error: downloaded file is not a script (wrong URL?)." >&2
  exit 1
fi

# 2. Install it as ~/.local/bin/php and make it executable
chmod 755 "$TMP"
mv -f "$TMP" "$BIN_DIR/php"

# 3. Soft link it as composer (relative link, so the pair can be moved together)
ln -sfn php "$BIN_DIR/composer"

echo "Installed:"
echo "  $BIN_DIR/php"
echo "  $BIN_DIR/composer -> php"

if ! command -v docker >/dev/null 2>&1; then
  echo "Warning: docker was not found. Install Docker before running php." >&2
fi

# 4. Make sure BIN_DIR is on PATH

# Detect the user's login shell ($SHELL), not the shell running this script
detect_shell() {
  user_shell="${SHELL:-}"
  if [ -z "$user_shell" ] && command -v getent >/dev/null 2>&1; then
    user_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
  fi
  basename "${user_shell:-sh}"
}

# Pick the rc file for a given shell name
rc_file_for() {
  case "$1" in
    bash) echo "$HOME/.bashrc" ;;
    zsh)  echo "${ZDOTDIR:-$HOME}/.zshrc" ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    ksh)  echo "$HOME/.kshrc" ;;
    *)    echo "$HOME/.profile" ;;
  esac
}

case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "$BIN_DIR is already in your PATH."
    ;;
  *)
    SHELL_NAME="$(detect_shell)"
    RC_FILE="$(rc_file_for "$SHELL_NAME")"

    if [ -f "$RC_FILE" ] && grep -qF '.local/bin' "$RC_FILE"; then
      echo "$RC_FILE already mentions .local/bin, leaving it unchanged."
    else
      mkdir -p "$(dirname "$RC_FILE")"
      {
        echo ""
        echo "# Added by the php docker installer"
        if [ "$SHELL_NAME" = "fish" ]; then
          echo 'set -gx PATH $HOME/.local/bin $PATH'
        else
          echo 'export PATH="$HOME/.local/bin:$PATH"'
        fi
      } >> "$RC_FILE"
      echo "Added $BIN_DIR to PATH in $RC_FILE (detected shell: $SHELL_NAME)."
    fi

    echo "Open a new terminal, or run:  source $RC_FILE"
    ;;
esac
