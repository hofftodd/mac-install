#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"
require_macos

# Security. Each setting is proposed separately; answer y to apply.
# Both of these need your password once (sudo, or your login password).
echo "macOS settings: security"

# --- Touch ID for sudo -------------------------------------------------------
# /etc/pam.d/sudo_local is the supported place for this (macOS 14+): unlike
# /etc/pam.d/sudo, macOS updates don't overwrite it.
SUDO_LOCAL=/etc/pam.d/sudo_local
TID_LINE='auth       sufficient     pam_tid.so'

if grep -qE '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' "$SUDO_LOCAL" 2>/dev/null; then
    echo "✓ Touch ID for sudo (already set)"
else
    echo
    echo "• Use Touch ID for sudo instead of typing your password"
    echo "    $SUDO_LOCAL: add '$TID_LINE' (asks for your password once)"
    if ask "  Apply?"; then
        if [ -f "$SUDO_LOCAL" ] && grep -qE '^#[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' "$SUDO_LOCAL"; then
            # Uncomment the line Apple's template ships with.
            sudo sed -i '' -E 's/^#[[:space:]]*(auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so)/\1/' "$SUDO_LOCAL"
        else
            echo "$TID_LINE" | sudo tee -a "$SUDO_LOCAL" >/dev/null
        fi
        restore_append "touch-id-sudo" \
            "sudo sed -i '' -E '/^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\\.so/d' $SUDO_LOCAL"
        mark_changed
        echo "  ✓ applied (open a new terminal tab to try: sudo -k && sudo true)"
        echo "  Note: inside tmux, Touch ID also needs pam_reattach (brew install pam-reattach)."
    else
        echo "  – skipped"
    fi
fi

# --- Password immediately after sleep or screen saver -------------------------
# Recent macOS ignores the old com.apple.screensaver askForPassword defaults;
# sysadminctl is the supported way to change this.
LOCK_STATUS="$(sysadminctl -screenLock status 2>&1 || true)"
if printf '%s' "$LOCK_STATUS" | grep -qi 'immediate'; then
    echo "✓ Require password immediately after sleep or screen saver (already set)"
else
    echo
    echo "• Require your password immediately after sleep or the screen saver starts"
    echo "    current: $(printf '%s' "$LOCK_STATUS" | tail -1)"
    if ask "  Apply?"; then
        echo "  sysadminctl will ask for your login password."
        sysadminctl -screenLock immediate -password -
        restore_append "screen-lock" \
            "# Screen lock delay was: $(printf '%s' "$LOCK_STATUS" | tail -1)" \
            "# Restore it in System Settings → Lock Screen, or: sysadminctl -screenLock <seconds|off> -password -"
        mark_changed
        echo "  ✓ applied"
    else
        echo "  – skipped"
    fi
fi

macos_settings_done
