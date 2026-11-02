#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

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

# Shell setup: zoxide init and eza aliases for ls (~/.zshrc.d/80-modern-cli.zsh)
install_zshrc_snippet 80-modern-cli <<'EOF'
# modern-cli init
eval "$(zoxide init zsh)"

# eza aliases
alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -l --group-directories-first --icons=auto --git'
alias la='eza -la --group-directories-first --icons=auto --git'
alias lt='eza --tree --level=2 --icons=auto'
EOF

echo "Modern CLI tools installed. Restart your shell or run: source ~/.zshrc"
