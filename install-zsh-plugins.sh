#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# zsh add-ons, loaded from ~/.zshrc.d/99-zsh-plugins.zsh:
#   zsh-autosuggestions      grey suggestions from your history as you type;
#                            → (or End) accepts one.
#   zsh-syntax-highlighting  commands turn red while mistyped, green when valid.
#   direnv                   loads a project's .envrc when you cd into it and
#                            unloads it when you leave (run `direnv allow` once
#                            per project to approve its .envrc).
# Syntax highlighting has to load after everything else that changes the
# command line (fzf, zoxide, starship...), hence the 99- prefix.
ensure_brew_on_path
brew install zsh-autosuggestions zsh-syntax-highlighting direnv

install_zshrc_snippet 99-zsh-plugins <<'SNIPPET'
# direnv: per-project environment variables from .envrc
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# Suggestions from history as you type (→ accepts).
[[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Syntax highlighting — must be the last thing loaded.
[[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
SNIPPET

echo "zsh plugins installed: autosuggestions, syntax highlighting, direnv."
echo "Restart your shell or run: source ~/.zshrc"
echo "direnv: put 'export FOO=bar' in a project's .envrc, then run 'direnv allow' there."
