#!/usr/bin/env bash
set -euo pipefail

# Look up the latest upstream versions of pinned tools and rewrite the
# defaults in the relevant install-*.sh scripts in place. Run this before
# install-master.sh to avoid stale pins. install-master.sh invokes it
# automatically as its first step.
#
# Sources:
#   nvm           — github.com/nvm-sh/nvm latest release
#   Python        — endoflife.date API (latest of the most recent stable cycle)
#   Nerd Fonts    — github.com/ryanoasis/nerd-fonts latest release
#
# Skipped (no reliable machine-readable source):
#   LM Studio     — download page is JS-rendered, no public manifest
#
# Note: Go on macOS is installed via brew, so its version isn't pinned here.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v jq >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        brew install jq
    else
        echo "jq not found and Homebrew not installed. Run bootstrap.sh first." >&2
        exit 1
    fi
fi

# BSD sed needs an explicit empty backup arg for -i; use a portable wrapper.
sed_inplace() {
    sed -i '' "$@"
}

update_default() {
    # update_default <file> <var-name> <new-value>
    local file="$1" var="$2" new="$3"
    if [ -z "$new" ] || [ "$new" = "null" ]; then
        echo "  ! could not resolve new version for $var (skipped)"
        return
    fi
    local before
    before="$(grep -E "^${var}=\"\\\$\\{${var}:-" "$file" | head -1 || true)"
    sed_inplace -E "s|^(${var}=\"\\\$\\{${var}:-)[^\"}]*(\\}\")|\\1${new}\\2|" "$file"
    local after
    after="$(grep -E "^${var}=\"\\\$\\{${var}:-" "$file" | head -1 || true)"
    if [ "$before" = "$after" ]; then
        echo "  = ${var} already at ${new}"
    else
        echo "  ✓ ${var}: $(echo "$before" | sed -E "s/.*:-([^}]*)\\}.*/\\1/") → ${new}"
    fi
}

update_plain() {
    # update_plain <file> <var-name> <new-value>
    local file="$1" var="$2" new="$3"
    if [ -z "$new" ] || [ "$new" = "null" ]; then
        echo "  ! could not resolve new version for $var (skipped)"
        return
    fi
    local before
    before="$(grep -E "^${var}=\"" "$file" | head -1 || true)"
    sed_inplace -E "s|^(${var}=\")[^\"]*(\")|\\1${new}\\2|" "$file"
    local after
    after="$(grep -E "^${var}=\"" "$file" | head -1 || true)"
    if [ "$before" = "$after" ]; then
        echo "  = ${var} already at ${new}"
    else
        echo "  ✓ ${var}: $(echo "$before" | sed -E 's/.*="([^"]*)".*/\1/') → ${new}"
    fi
}

echo "Resolving latest versions..."

NVM_LATEST="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .tag_name)"
echo "nvm:        ${NVM_LATEST}"
update_default "${DIR}/install-nodejs.sh" "NVM_VERSION" "$NVM_LATEST"

PY_LATEST="$(curl -fsSL https://endoflife.date/api/python.json | jq -r '[.[] | select(.eol > (now | strftime("%Y-%m-%d")))] | .[0].latest')"
echo "Python:     ${PY_LATEST}"
update_default "${DIR}/install-pyenv.sh" "PYTHON_VERSION" "$PY_LATEST"

NF_LATEST="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r .tag_name | sed 's/^v//')"
echo "Nerd Fonts: ${NF_LATEST}"
update_plain "${DIR}/install-nerd-fonts.sh" "VERSION" "$NF_LATEST"

echo
echo "Skipped (manual check needed):"
echo "  - install-lmstudio.sh    — LM Studio cask is auto-updated by brew"
echo
echo "Done."
