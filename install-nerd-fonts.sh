#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Install a selection of Nerd Fonts via Homebrew casks.
# See https://www.nerdfonts.com/

# Cask names: each is `font-<name>-nerd-font`.
FONTS=(
    font-fira-code-nerd-font
    font-jetbrains-mono-nerd-font
    font-hack-nerd-font
    font-meslo-lg-nerd-font
    font-caskaydia-cove-nerd-font
)

for font in "${FONTS[@]}"; do
    cask_install "$font"
done

echo "Nerd Fonts installed (brew upgrade keeps them current)."
