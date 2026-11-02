#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Install opencode, an open-source AI coding agent for the terminal.
# See https://opencode.ai/ and https://github.com/sst/opencode
curl -fsSL https://opencode.ai/install | bash

install_zshrc_snippet 10-local-bin <<'EOF'
export PATH="$HOME/.local/bin:$PATH"
EOF

echo "opencode installed. Restart your shell or run: source ~/.zshrc"
echo "Then run: opencode"
