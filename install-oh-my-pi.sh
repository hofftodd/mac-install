#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Install Oh My Pi, an AI coding agent for the terminal — hash-anchored edits,
# LSP, Python, browser, subagents, etc. (an extension of pi).
# Binary lands at ~/.local/bin/omp.
# See https://github.com/can1357/oh-my-pi
curl -fsSL https://raw.githubusercontent.com/can1357/oh-my-pi/main/scripts/install.sh | sh

install_zshrc_snippet 10-local-bin <<'EOF'
export PATH="$HOME/.local/bin:$PATH"
EOF

echo "Oh My Pi installed. Restart your shell or run: source ~/.zshrc"
echo "Then run: omp"
