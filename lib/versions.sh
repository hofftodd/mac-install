# shellcheck shell=bash
# Version defaults saved by update-versions.sh.
#
# update-versions.sh looks up the latest upstream versions and writes them to
# ~/.mac-install/versions.env (outside the repo, so the checkout stays clean).
# Install scripts source this file to pick them up:
#
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/versions.sh"
#   NVM_VERSION="${NVM_VERSION:-v0.40.4}"     # built-in fallback
#
# Precedence: a variable you set yourself (NVM_VERSION=... ./install-nodejs.sh)
# wins, then the saved file, then the script's built-in fallback.
#
# Bash 3.2 compatible (macOS /bin/bash).

MAC_INSTALL_VERSIONS_FILE="${MAC_INSTALL_VERSIONS_FILE:-$HOME/.mac-install/versions.env}"

if [ -f "$MAC_INSTALL_VERSIONS_FILE" ]; then
    while IFS='=' read -r _key _value; do
        case "$_key" in
            '' | \#*) continue ;;
        esac
        # Only plain NAME=value lines; never override something already set.
        case "$_key" in
            *[!A-Za-z0-9_]*) continue ;;
        esac
        if [ -z "${!_key:-}" ]; then
            export "$_key=$_value"
        fi
    done < "$MAC_INSTALL_VERSIONS_FILE"
    unset _key _value
fi
