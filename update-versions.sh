#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Look up the latest upstream versions of pinned tools and save them to
# ~/.mac-install/versions.env. Install scripts read that file (lib/versions.sh)
# and fall back to their built-in defaults when it's missing, so this is
# optional; install-master.sh runs it first by default.
#
# The repo itself is never modified, so the checkout stays clean.
#
# Saved values:
#   NVM_VERSION           — newest nvm-sh/nvm release tag (install-nodejs.sh)
#   PG_LATEST_FORMULA     — newest PostgreSQL major that Homebrew has as
#                           postgresql@N, per endoflife.date (install-postgres.sh)
#
# Not pinned (always latest anyway):
#   Python (uv), Rust (rustup), Bun, Go and every other Homebrew package or
#   cask — `brew upgrade` keeps those current.

VERSIONS_FILE="${MAC_INSTALL_VERSIONS_FILE:-$HOME/.mac-install/versions.env}"

ensure_brew_on_path
if ! command -v jq >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        brew install jq
    else
        echo "jq not found and Homebrew not installed. Run bootstrap.sh first." >&2
        exit 1
    fi
fi

# Previously saved value of a key (empty if none).
saved() {
    [ -f "$VERSIONS_FILE" ] || return 0
    grep -E "^$1=" "$VERSIONS_FILE" | tail -1 | cut -d= -f2- || true
}

NEW_LINES=()

# record <KEY> <value> <label> — report the change and queue it for saving.
# An empty value (lookup failed) keeps whatever was saved before.
record() {
    local key="$1" new="$2" label="$3" old
    old="$(saved "$key")"
    if [ -z "$new" ] || [ "$new" = "null" ]; then
        printf '  ! %-12s could not look up the latest version' "$label"
        if [ -n "$old" ]; then printf ' (keeping %s)\n' "$old"; else printf ' (scripts use their built-in default)\n'; fi
        [ -n "$old" ] && NEW_LINES+=("$key=$old")
        return 0
    fi
    if [ "$old" = "$new" ]; then
        printf '  = %-12s %s\n' "$label" "$new"
    elif [ -n "$old" ]; then
        printf '  ✓ %-12s %s → %s\n' "$label" "$old" "$new"
    else
        printf '  ✓ %-12s %s\n' "$label" "$new"
    fi
    NEW_LINES+=("$key=$new")
}

echo "Resolving latest versions..."

# Newest vX.Y.Z release tag, read with git rather than GitHub's API (which
# rate-limits anonymous requests). Numeric sort works with macOS's sort.
NVM_LATEST="$(git ls-remote --tags --refs https://github.com/nvm-sh/nvm.git 2>/dev/null \
    | sed -n 's|.*refs/tags/v\([0-9]*\.[0-9]*\.[0-9]*\)$|\1|p' \
    | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 || true)"
[ -n "$NVM_LATEST" ] && NVM_LATEST="v$NVM_LATEST"
record NVM_VERSION "$NVM_LATEST" "nvm"

# Newest PostgreSQL major (endoflife.date lists cycles newest first) that
# Homebrew already packages as postgresql@N. A brand-new major can appear
# upstream before Homebrew has it, so fall back to the next one down.
PG_LATEST=""
for major in $(curl -fsSL https://endoflife.date/api/postgresql.json | jq -r '.[].cycle' 2>/dev/null | head -3 || true); do
    if curl -fsS -o /dev/null "https://formulae.brew.sh/api/formula/postgresql@${major}.json" 2>/dev/null; then
        PG_LATEST="postgresql@${major}"
        break
    fi
done
record PG_LATEST_FORMULA "$PG_LATEST" "PostgreSQL"

mkdir -p "$(dirname "$VERSIONS_FILE")"
{
    echo "# Written by mac-install/update-versions.sh on $(date '+%Y-%m-%d %H:%M')."
    echo "# Read by the install scripts via lib/versions.sh. Safe to delete:"
    echo "# scripts then fall back to their built-in defaults."
    # (the +"..." form keeps bash 3.2 happy under set -u when nothing resolved)
    if [ "${#NEW_LINES[@]}" -gt 0 ]; then printf '%s\n' ${NEW_LINES[@]+"${NEW_LINES[@]}"}; fi
} > "$VERSIONS_FILE"

echo
echo "Saved to $VERSIONS_FILE"
