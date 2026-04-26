#!/usr/bin/env bash
set -euo pipefail

# Go via Homebrew. See https://go.dev/
brew install go

# Ensure $GOPATH/bin is on PATH in ~/.zshrc
if ! grep -q 'GOPATH' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
EOF
fi

echo "Go installed: $(go version)"
echo "Restart your shell or run: source ~/.zshrc"
