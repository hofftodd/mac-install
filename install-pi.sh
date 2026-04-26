#!/usr/bin/env bash
set -euo pipefail

# Install pi (https://pi.dev/), a minimal terminal-based coding agent.
# Distributed as an npm package, so we need Node available — load nvm if
# the user installed it via install-nodejs.sh.
if ! command -v npm >/dev/null 2>&1; then
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck disable=SC1091
        \. "$NVM_DIR/nvm.sh"
    fi
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "npm not found. Run ./install-nodejs.sh first (or install Node another way)." >&2
    exit 1
fi

npm install -g @mariozechner/pi-coding-agent

echo "pi installed: $(pi --version 2>/dev/null || echo 'run: pi --help')"
