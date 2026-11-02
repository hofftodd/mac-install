#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/versions.sh"

# little-coder, an AI coding agent CLI published on npm.
# See https://github.com/itayinbarr/little-coder
#
# Pinned to a specific release rather than piping the project's install.sh
# from its main branch: that script only checks the Node version and runs
# `npm install -g little-coder` (whatever is newest), so we do the same steps
# here with an exact version. update-versions.sh reports newer releases;
# bump the pin below (or set LITTLE_CODER_VERSION) after reviewing them.
LITTLE_CODER_VERSION="${LITTLE_CODER_VERSION:-1.20.0}"

# Needs Node 22.19+ — install-nodejs.sh sets that up via nvm. Source nvm so
# node/npm are on PATH even in this non-interactive shell.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "Node.js/npm not found. Run install-nodejs.sh first (little-coder needs Node 22.19+)." >&2
    exit 1
fi
if ! node -e 'const [a, b] = process.versions.node.split(".").map(Number); process.exit(a > 22 || (a === 22 && b >= 19) ? 0 : 1)'; then
    echo "Node $(node --version) is too old: little-coder needs 22.19+. Try: nvm install --lts" >&2
    exit 1
fi

INSTALLED="$(npm ls -g --depth=0 --json 2>/dev/null | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write((JSON.parse(s).dependencies||{})["little-coder"]?.version||"")}catch{}})' || true)"
if [ "$INSTALLED" = "$LITTLE_CODER_VERSION" ]; then
    echo "little-coder $LITTLE_CODER_VERSION is already installed."
else
    npm install -g "little-coder@$LITTLE_CODER_VERSION"
fi

echo "little-coder $LITTLE_CODER_VERSION installed (in Node $(node --version)'s global packages)."
echo "Then run: little-coder --list-models"
