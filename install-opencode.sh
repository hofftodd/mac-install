#!/usr/bin/env bash
set -euo pipefail

# Install opencode, an open-source AI coding agent for the terminal.
# See https://opencode.ai/ and https://github.com/sst/opencode
curl -fsSL https://opencode.ai/install | bash

if ! grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

echo "opencode installed. Restart your shell or run: source ~/.zshrc"
echo "Then run: opencode"
