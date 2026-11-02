#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Go via Homebrew. See https://go.dev/
brew install go

# Put $GOPATH/bin on PATH (~/.zshrc.d/20-go.zsh)
install_zshrc_snippet 20-go <<'EOF'
# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
EOF

echo "Go installed: $(go version)"
echo "Restart your shell or run: source ~/.zshrc"
