#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"

# macOS settings: run this Mac as an always-on server — stay awake, come back
# by itself after a power cut or freeze, and be reachable over the network.
# Most of these need your password once (sudo).
#
# Power settings apply to the "AC Power" profile only (pmset -c) where the Mac
# has one, so a laptop keeps its normal battery behaviour and only stays awake
# while plugged in. Desktops without separate profiles use pmset -a.
#
# Run with no arguments to be asked about each setting, with setting ids to
# apply just those, or with --list to see the ids. install-master.sh shows each
# setting as its own checkbox.

# --- Power (pmset) -------------------------------------------------------------

# Laptops list settings per power source ("Battery Power:", "AC Power:"); use
# the AC profile there (pmset -c). If there's no AC section (some desktop
# Macs print a single list), read that list and change all sources (pmset -a).
if pmset -g custom 2>/dev/null | grep -q '^AC Power'; then
    PM_SCOPE=-c
else
    PM_SCOPE=-a
fi

# pm_get <key> — the key's current value (empty if this Mac doesn't have it).
pm_get() {
    pmset -g custom 2>/dev/null | awk -v key="$1" '
        /^AC Power/ { ac = 1; seen = 1; next }
        /^[A-Za-z].*:[[:space:]]*$/ { ac = 0; next }
        $1 == key {
            if (ac) acv = $2
            else if (!anyset) { anyv = $2; anyset = 1 }
        }
        END { if (seen) print acv; else print anyv }'
}

# pm_setting <key> <value> <is_set|describe|apply>
pm_setting() {
    local key="$1" want="$2" cur
    cur="$(pm_get "$key")"
    case "$3" in
        is_set)
            # A Mac without this setting (e.g. autorestart on some laptops)
            # has nothing to change.
            if [ -z "$cur" ]; then
                echo "  ($key isn't available on this Mac — nothing to change)"
                return 0
            fi
            [ "$cur" = "$want" ]
            ;;
        describe)
            echo "    pmset $PM_SCOPE $key: ${cur:-not available} → $want"
            ;;
        apply)
            sudo pmset "$PM_SCOPE" "$key" "$want" || return 1
            restore_append "pmset $key" "sudo pmset $PM_SCOPE $key $cur"
            ;;
    esac
}

never_sleep() { pm_setting sleep 0 "$1"; }
disk_sleep() { pm_setting disksleep 0 "$1"; }
power_restart() { pm_setting autorestart 1 "$1"; }
wake_network() { pm_setting womp 1 "$1"; }

# --- Restart after a freeze (systemsetup) --------------------------------------

restart_freeze() {
    case "$1" in
        is_set)
            # Reading it needs admin rights; if sudo isn't cached, treat as not set.
            sudo -n systemsetup -getrestartfreeze 2>/dev/null | grep -qi ': on'
            ;;
        describe)
            echo "    systemsetup restart after freeze: → On"
            ;;
        apply)
            sudo systemsetup -setrestartfreeze on || return 1
            restore_append "restart-freeze" "sudo systemsetup -setrestartfreeze off"
            ;;
    esac
}

# --- Remote access --------------------------------------------------------------

# port_open <port> — something is listening on localhost:<port>.
port_open() { nc -z -G 2 127.0.0.1 "$1" >/dev/null 2>&1; }

remote_login() {
    case "$1" in
        is_set) port_open 22 ;;
        describe) echo "    Remote Login (SSH, port 22): off → on" ;;
        apply)
            # Recent macOS only allows this if your terminal app has Full Disk
            # Access; otherwise point to the switch in System Settings.
            if ! sudo systemsetup -setremotelogin on; then
                echo "  Couldn't turn on Remote Login from the terminal. Either:"
                echo "    • System Settings → General → Sharing → Remote Login, or"
                echo "    • give your terminal Full Disk Access (System Settings → Privacy & Security) and re-run."
                return 1
            fi
            restore_append "remote-login" "sudo systemsetup -setremotelogin off"
            echo "  Connect with: ssh $(id -un)@$(scutil --get LocalHostName 2>/dev/null || hostname).local"
            ;;
    esac
}

screen_sharing() {
    case "$1" in
        is_set) port_open 5900 ;;
        describe) echo "    Screen Sharing (VNC, port 5900): off → on" ;;
        apply)
            if sudo launchctl enable system/com.apple.screensharing \
                && { sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null \
                    || port_open 5900; }; then
                restore_append "screen-sharing" \
                    "sudo launchctl bootout system/com.apple.screensharing 2>/dev/null; sudo launchctl disable system/com.apple.screensharing"
                echo "  Connect from another Mac with Finder → Go → Connect to Server: vnc://$(scutil --get LocalHostName 2>/dev/null || hostname).local"
            else
                echo "  Couldn't turn on Screen Sharing from the terminal."
                echo "    Use System Settings → General → Sharing → Screen Sharing."
                return 1
            fi
            ;;
    esac
}

# --- Updates --------------------------------------------------------------------

SU_PLIST=/Library/Preferences/com.apple.SoftwareUpdate
no_auto_macos_updates() {
    local cur
    cur="$(defaults read "$SU_PLIST" AutomaticallyInstallMacOSUpdates 2>/dev/null || true)"
    case "$1" in
        is_set) [ "$cur" = 0 ] ;;
        describe)
            echo "    $SU_PLIST AutomaticallyInstallMacOSUpdates: ${cur:-not set (macOS default)} → false"
            echo "    (security responses and data files still install; macOS updates wait for you)"
            ;;
        apply)
            sudo defaults write "$SU_PLIST" AutomaticallyInstallMacOSUpdates -bool false || return 1
            if [ -n "$cur" ]; then
                if [ "$cur" = 1 ]; then cur=true; else cur=false; fi
                restore_append "auto-macos-updates" "sudo defaults write $SU_PLIST AutomaticallyInstallMacOSUpdates -bool $cur"
            else
                restore_append "auto-macos-updates" "sudo defaults delete $SU_PLIST AutomaticallyInstallMacOSUpdates 2>/dev/null || true"
            fi
            ;;
    esac
}

custom_setting never-sleep "Never sleep on power (laptops: when plugged in)" never_sleep
custom_setting disk-sleep "Disks never sleep" disk_sleep
custom_setting restart-power "Restart automatically after a power failure" power_restart
custom_setting restart-freeze "Restart automatically if the system freezes" restart_freeze
custom_setting wake-network "Wake for network access" wake_network
custom_setting remote-login "Remote Login (SSH)" remote_login
custom_setting screen-sharing "Screen Sharing (VNC)" screen_sharing
custom_setting no-auto-macos-updates "Don't auto-install macOS updates (they restart)" no_auto_macos_updates

run_settings "$@"
macos_settings_done
cat <<'EOF'
Also worth doing by hand for a server:
  • Apps that need a logged-in user (Ollama, Syncthing, Tailscale apps) only start
    after a reboot if someone logs in: System Settings → Users & Groups →
    "Automatically log in as" (needs FileVault off — a security trade-off).
  • Give it a stable name: System Settings → General → Sharing → Local hostname.
  • Check what's keeping it awake or asleep: pmset -g assertions
EOF
