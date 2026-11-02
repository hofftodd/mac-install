#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"

# macOS settings: security. Both settings ask for your password once (sudo,
# or your login password for sysadminctl).
# Run with no arguments to be asked about each setting, with setting ids to
# apply just those, or with --list to see the ids. install-master.sh shows each
# setting as its own checkbox.

# --- Touch ID for sudo -------------------------------------------------------
# /etc/pam.d/sudo_local is the supported place for this (macOS 14+): unlike
# /etc/pam.d/sudo, macOS updates don't overwrite it.
SUDO_LOCAL=/etc/pam.d/sudo_local
TID_LINE='auth       sufficient     pam_tid.so'

touch_id_sudo() {
    case "$1" in
        is_set)
            grep -qE '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' "$SUDO_LOCAL" 2>/dev/null
            ;;
        describe)
            echo "    $SUDO_LOCAL: add '$TID_LINE' (asks for your password once)"
            ;;
        apply)
            if [ -f "$SUDO_LOCAL" ] && grep -qE '^#[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' "$SUDO_LOCAL"; then
                # Uncomment the line Apple's template ships with.
                sudo sed -i '' -E 's/^#[[:space:]]*(auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so)/\1/' "$SUDO_LOCAL" || return 1
            else
                echo "$TID_LINE" | sudo tee -a "$SUDO_LOCAL" >/dev/null || return 1
            fi
            restore_append "touch-id-sudo" \
                "sudo sed -i '' -E '/^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\\.so/d' $SUDO_LOCAL"
            echo "  Try it in a new terminal tab: sudo -k && sudo true"
            echo "  Inside tmux, Touch ID also needs pam_reattach (brew install pam-reattach)."
            ;;
    esac
}

# --- Password immediately after sleep or screen saver -------------------------
# Recent macOS ignores the old com.apple.screensaver askForPassword defaults;
# sysadminctl is the supported way to change this.
screen_lock_status() { sysadminctl -screenLock status 2>&1 | tail -1 || true; }

screen_lock() {
    case "$1" in
        is_set)
            screen_lock_status | grep -qi 'immediate'
            ;;
        describe)
            echo "    current: $(screen_lock_status)"
            ;;
        apply)
            local before
            before="$(screen_lock_status)"
            echo "  sysadminctl will ask for your login password."
            sysadminctl -screenLock immediate -password - || return 1
            restore_append "screen-lock" \
                "# Screen lock delay was: $before" \
                "# Restore it in System Settings → Lock Screen, or: sysadminctl -screenLock <seconds|off> -password -"
            ;;
    esac
}

custom_setting touch-id-sudo "Touch ID for sudo" touch_id_sudo
custom_setting screen-lock "Password immediately after sleep" screen_lock

run_settings "$@"
macos_settings_done
