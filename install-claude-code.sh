#!/usr/bin/env bash
set -euo pipefail

# Install Claude Code, Anthropic's official CLI.
# See https://docs.claude.com/en/docs/claude-code/setup
curl -fsSL https://claude.ai/install.sh | bash

# The installer drops the binary at ~/.local/bin/claude — make sure that's on PATH.
if ! grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

echo "Claude Code installed. Restart your shell or run: source ~/.zshrc"
echo "Then run: claude   (first launch will prompt you to authenticate)"
