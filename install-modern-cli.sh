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

# Replace ls with eza. Separate marker so machines that already have the
# zoxide block still pick this up on re-run.
if ! grep -q '# eza aliases' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# eza aliases
alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -l --group-directories-first --icons=auto --git'
alias la='eza -la --group-directories-first --icons=auto --git'
alias lt='eza --tree --level=2 --icons=auto'
EOF
fi

echo "Modern CLI tools installed. Restart your shell or run: source ~/.zshrc"
