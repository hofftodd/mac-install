#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Install Claude Code, Anthropic's official CLI.
# See https://docs.claude.com/en/docs/claude-code/setup
curl -fsSL https://claude.ai/install.sh | bash

# The installer drops the binary at ~/.local/bin/claude — make sure that's on PATH.
install_zshrc_snippet 10-local-bin <<'EOF'
export PATH="$HOME/.local/bin:$PATH"
EOF

echo "Claude Code installed. Restart your shell or run: source ~/.zshrc"
echo "Then run: claude   (first launch will prompt you to authenticate)"
