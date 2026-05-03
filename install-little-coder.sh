#!/usr/bin/env bash
set -euo pipefail

# Install little-coder, an AI coding agent CLI distributed as an npm package.
# See https://github.com/itayinbarr/little-coder
#
# Requires Node.js 20.6+ — install-nodejs.sh sets that up via nvm.

# Source nvm so npm is on PATH even in this non-interactive shell.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v npm >/dev/null 2>&1; then
    echo "npm not found. Run install-nodejs.sh first (or otherwise install Node 20.6+)." >&2
    exit 1
fi

curl -fsSL https://raw.githubusercontent.com/itayinbarr/little-coder/main/install.sh | bash

if ! grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

echo "little-coder installed. Restart your shell or run: source ~/.zshrc"
echo "Then run: little-coder"
