#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Starship prompt. See https://starship.rs/
brew install starship

install_zshrc_snippet 90-starship <<'EOF'
eval "$(starship init zsh)"
EOF

# Apply the Gruvbox Rainbow preset.
mkdir -p "$HOME/.config"
starship preset gruvbox-rainbow -o "$HOME/.config/starship.toml"

echo "Starship installed with Gruvbox Rainbow preset. Restart your shell or run: source ~/.zshrc"
echo "Set your terminal's font to a Nerd Font (e.g. 'CaskaydiaCove Nerd Font Mono') so the powerline glyphs render correctly."
echo "  Terminal.app:  Settings → Profiles → Text → Change... → CaskaydiaCove Nerd Font Mono"
echo "  iTerm2:        Settings → Profiles → Text → Font"
