#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Starship prompt. See https://starship.rs/
brew install starship

install_zshrc_snippet 90-starship <<'EOF'
eval "$(starship init zsh)"
EOF

# Apply the Gruvbox Rainbow preset — only if there's no config yet, so
# re-running never overwrites your own changes.
STARSHIP_CONFIG_FILE="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
if [ -e "$STARSHIP_CONFIG_FILE" ]; then
    echo "Keeping your existing $STARSHIP_CONFIG_FILE."
    echo "  To switch to the Gruvbox Rainbow preset: starship preset gruvbox-rainbow -o $STARSHIP_CONFIG_FILE"
else
    mkdir -p "$(dirname "$STARSHIP_CONFIG_FILE")"
    starship preset gruvbox-rainbow -o "$STARSHIP_CONFIG_FILE"
    echo "Applied the Gruvbox Rainbow preset to $STARSHIP_CONFIG_FILE."
fi

echo "Starship installed. Restart your shell or run: source ~/.zshrc"
echo "Set your terminal's font to a Nerd Font (e.g. 'CaskaydiaCove Nerd Font Mono') so the powerline glyphs render correctly."
echo "  Terminal.app:  Settings → Profiles → Text → Change... → CaskaydiaCove Nerd Font Mono"
echo "  iTerm2:        Settings → Profiles → Text → Font"
