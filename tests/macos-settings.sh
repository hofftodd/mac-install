#!/usr/bin/env bash
# Applies macOS settings for real, checks them, re-runs them, then runs the
# generated restore script and checks the originals came back.
#
# ONLY run this on a throwaway Mac (the GitHub Actions runner): it changes
# Dock, Finder, keyboard, screenshot, trackpad, power and sudo settings.
# Scripts run under /bin/bash (3.2), the version a new Mac has.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [ "$(uname -s)" != Darwin ] || [ "${CI:-}" != true ]; then
    echo "Refusing to run: this changes system settings. Only for macOS CI runners (CI=true)." >&2
    exit 1
fi

BASH32=/bin/bash
export MACOS_RESTORE_DIR
MACOS_RESTORE_DIR="$(mktemp -d)"
RESTORE="$MACOS_RESTORE_DIR/restore-macos-defaults.sh"

failures=0
pass() { echo "  ✓ $*"; }
fail() {
    echo "  ✗ $*"
    failures=$((failures + 1))
}

# read_default <domain> <key> — value, or "<unset>". currentHost:<domain> supported.
read_default() {
    case "$1" in
        currentHost:*) defaults -currentHost read "${1#currentHost:}" "$2" 2>/dev/null || echo "<unset>" ;;
        *) defaults read "$1" "$2" 2>/dev/null || echo "<unset>" ;;
    esac
}

# Each case: script | setting id | domain | key | expected value after applying
# (as `defaults read` prints it: booleans are 1/0).
CASES='macos-dock.sh|tilesize|com.apple.dock|tilesize|48
macos-dock.sh|no-recents|com.apple.dock|show-recents|0
macos-dock.sh|autohide-delay|com.apple.dock|autohide-delay|0
macos-finder.sh|show-extensions|NSGlobalDomain|AppleShowAllExtensions|1
macos-finder.sh|path-bar|com.apple.finder|ShowPathbar|1
macos-finder.sh|list-view|com.apple.finder|FXPreferredViewStyle|Nlsv
macos-keyboard.sh|smart-quotes|NSGlobalDomain|NSAutomaticQuoteSubstitutionEnabled|0
macos-keyboard.sh|key-repeat|NSGlobalDomain|KeyRepeat|2
macos-screenshots.sh|png|com.apple.screencapture|type|png
macos-trackpad.sh|tap-to-click|currentHost:NSGlobalDomain|com.apple.mouse.tapBehavior|1
macos-misc.sh|expand-save|NSGlobalDomain|NSNavPanelExpandedStateForSaveMode|1'

# Record originals.
ORIGINALS=""
while IFS='|' read -r script id domain key want; do
    ORIGINALS="$ORIGINALS$domain|$key|$(read_default "$domain" "$key")"$'\n'
done <<< "$CASES"

echo "== Applying settings by id (as the menu does)"
for script in $(printf '%s\n' "$CASES" | cut -d'|' -f1 | sort -u); do
    ids="$(printf '%s\n' "$CASES" | awk -F'|' -v s="$script" '$1 == s { print $2 }' | tr '\n' ' ')"
    # shellcheck disable=SC2086  # ids is a space-separated list
    $BASH32 "./$script" $ids
done

echo "== Checking values"
while IFS='|' read -r script id domain key want; do
    got="$(read_default "$domain" "$key")"
    if [ "$got" = "$want" ]; then pass "$script $id: $key = $got"; else fail "$script $id: $key = $got (expected $want)"; fi
done <<< "$CASES"

echo "== Re-running: every setting should report 'already set' and change nothing"
for script in $(printf '%s\n' "$CASES" | cut -d'|' -f1 | sort -u); do
    ids="$(printf '%s\n' "$CASES" | awk -F'|' -v s="$script" '$1 == s { print $2 }' | tr '\n' ' ')"
    # shellcheck disable=SC2086
    out="$($BASH32 "./$script" $ids)"
    n_ids="$(echo $ids | wc -w | tr -d ' ')"
    n_already="$(printf '%s\n' "$out" | grep -c '(already set)' || true)"
    if [ "$n_already" = "$n_ids" ] && printf '%s\n' "$out" | grep -q 'No changes made'; then
        pass "$script: $n_ids already set, no changes"
    else
        fail "$script: expected $n_ids '(already set)' and 'No changes made', got:"$'\n'"$out"
    fi
done

echo "== Asking with no terminal must change nothing"
before="$(read_default com.apple.dock mru-spaces)"
$BASH32 ./macos-dock.sh < /dev/null > /dev/null 2>&1 || true
after="$(read_default com.apple.dock mru-spaces)"
if [ "$before" = "$after" ]; then pass "no-terminal run left mru-spaces at $after"; else fail "no-terminal run changed mru-spaces $before → $after"; fi

echo "== Unknown id is rejected before anything changes"
if $BASH32 ./macos-dock.sh fixed-spaces no-such-setting > /dev/null 2>&1; then
    fail "unknown id was accepted"
elif [ "$(read_default com.apple.dock mru-spaces)" = "$before" ]; then
    pass "unknown id rejected, nothing applied"
else
    fail "unknown id rejected but fixed-spaces was applied anyway"
fi

echo "== Always-on server power settings (sudo is passwordless on runners)"
pm_value() {
    pmset -g custom | awk -v key="$1" '
        /^AC Power/ { ac = 1; seen = 1; next }
        /^[A-Za-z].*:[[:space:]]*$/ { ac = 0; next }
        $1 == key { if (ac) acv = $2; else if (!anyset) { anyv = $2; anyset = 1 } }
        END { if (seen) print acv; else print anyv }'
}
echo "pmset -g custom on this runner:"
pmset -g custom | sed 's/^/    /'
# Runners usually ship with sleep/disksleep already 0, which would only test
# the "already set" path. Start from 10 so the change and restore really run.
PM_RUNNER_SLEEP="$(pm_value sleep)"
PM_RUNNER_DISKSLEEP="$(pm_value disksleep)"
sudo pmset -a sleep 10 disksleep 10
PM_ORIG_SLEEP="$(pm_value sleep)"
PM_ORIG_DISKSLEEP="$(pm_value disksleep)"
[ "$PM_ORIG_SLEEP" = 10 ] || fail "couldn't set up the pmset test (sleep is $PM_ORIG_SLEEP)"
$BASH32 ./macos-server.sh never-sleep disk-sleep
if [ "$(pm_value sleep)" = 0 ]; then pass "sleep = 0"; else fail "sleep = $(pm_value sleep) (expected 0)"; fi
if [ "$(pm_value disksleep)" = 0 ]; then pass "disksleep = 0"; else fail "disksleep = $(pm_value disksleep) (expected 0)"; fi

echo "== Touch ID for sudo (edits /etc/pam.d/sudo_local)"
PAM_BEFORE="$(cat /etc/pam.d/sudo_local 2>/dev/null || echo '<missing>')"
$BASH32 ./macos-security.sh touch-id-sudo
if grep -qE '^auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' /etc/pam.d/sudo_local; then pass "pam_tid enabled"; else fail "pam_tid line not found"; fi
if sudo -n true; then pass "sudo still works"; else fail "sudo broken after Touch ID change"; fi

echo "== Running the restore script"
echo "---- $RESTORE"
sed 's/^/    /' "$RESTORE"
echo "----"
$BASH32 "$RESTORE"

echo "== Checking originals are back"
while IFS='|' read -r domain key orig; do
    [ -n "$domain" ] || continue
    got="$(read_default "$domain" "$key")"
    if [ "$got" = "$orig" ]; then pass "$key back to $orig"; else fail "$key = $got after restore (expected $orig)"; fi
done <<< "$ORIGINALS"
[ "$(pm_value sleep)" = "$PM_ORIG_SLEEP" ] && pass "pmset sleep back to $PM_ORIG_SLEEP" || fail "pmset sleep = $(pm_value sleep) (expected $PM_ORIG_SLEEP)"
[ "$(pm_value disksleep)" = "$PM_ORIG_DISKSLEEP" ] && pass "pmset disksleep back to $PM_ORIG_DISKSLEEP" || fail "pmset disksleep = $(pm_value disksleep) (expected $PM_ORIG_DISKSLEEP)"
sudo pmset -a sleep "$PM_RUNNER_SLEEP" disksleep "$PM_RUNNER_DISKSLEEP"   # leave the runner as we found it
PAM_AFTER="$(cat /etc/pam.d/sudo_local 2>/dev/null || echo '<missing>')"
if ! grep -qE '^auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' <<< "$PAM_AFTER"; then pass "pam_tid removed again"; else fail "pam_tid still enabled after restore (was: $PAM_BEFORE)"; fi

echo
if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed."
    exit 1
fi
echo "✓ all macOS settings checks passed"
