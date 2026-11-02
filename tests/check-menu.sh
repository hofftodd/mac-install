#!/usr/bin/env bash
# Consistency checks that don't need a Mac: every menu item points at a real,
# executable script; every script is in the menu and the README; settings ids
# are unique; each script uses strict mode.
#
# Run from anywhere: tests/check-menu.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

failures=0
fail() {
    echo "✗ $*"
    failures=$((failures + 1))
}

ITEMS="$(./install-master.sh --list)"
[ -n "$ITEMS" ] || { echo "✗ install-master.sh --list printed nothing"; exit 1; }
echo "Menu items: $(printf '%s\n' "$ITEMS" | wc -l | tr -d ' ')"

# Every item's script exists and is executable; labels aren't empty.
while IFS='|' read -r category ticked command label; do
    script="${command%% *}"
    [ -x "$script" ] || fail "$category: $script is missing or not executable"
    [ -n "$label" ] || fail "$category: empty label for '$command'"
    case "$ticked" in 0 | 1) ;; *) fail "$command: bad ticked value '$ticked'" ;; esac
done <<< "$ITEMS"

# Every script in the repo is in the menu and documented in the README.
for script in install-*.sh macos-*.sh update-versions.sh; do
    [ "$script" = install-master.sh ] && continue
    printf '%s\n' "$ITEMS" | cut -d'|' -f3 | grep -qE "^\./$script( |$)" \
        || fail "$script is not in the install-master.sh menu"
    grep -qF "\`$script\`" README.md || fail "$script is not described in README.md"
done

# macOS settings: each script lists its settings, with unique ids.
for script in macos-*.sh; do
    ids="$(./"$script" --list | cut -d'|' -f1)"
    [ -n "$ids" ] || fail "$script --list printed nothing"
    dupes="$(printf '%s\n' "$ids" | sort | uniq -d)"
    [ -z "$dupes" ] || fail "$script has duplicate setting ids: $dupes"
done

# Every script runs in strict mode (except the menu, which has to keep going
# when a script it runs fails).
for script in *.sh tests/*.sh; do
    [ "$script" = install-master.sh ] && continue
    grep -q '^set -euo pipefail' "$script" || fail "$script doesn't use 'set -euo pipefail'"
done

if [ "$failures" -gt 0 ]; then
    echo "$failures problem(s) found."
    exit 1
fi
echo "✓ menu, scripts and README are consistent"
