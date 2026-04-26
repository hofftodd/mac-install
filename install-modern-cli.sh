#!/usr/bin/env bash
set -euo pipefail

# Install a bundle of modern CLI quality-of-life tools.
#   ripgrep    — fast grep (rg)
#   fd         — fast find
#   bat        — cat with syntax highlighting
#   eza        — modern ls
#   fzf        — fuzzy finder
#   zoxide     — smarter cd
#   git-delta  — better git diff viewer
#   jq, yq     — JSON / YAML query tools
#   tree, htop, ncdu — directory tree, process monitor, disk usage
brew install \
    ripgrep fd bat eza fzf zoxide git-delta jq yq tree htop ncdu

# zoxide init in ~/.zshrc
if ! grep -q '# modern-cli init' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# modern-cli init
eval "$(zoxide init zsh)"
EOF
fi

echo "Modern CLI tools installed. Restart your shell or run: source ~/.zshrc"
