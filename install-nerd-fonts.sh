#!/usr/bin/env bash
set -euo pipefail

# Install a selection of Nerd Fonts via Homebrew casks.
# See https://www.nerdfonts.com/
# VERSION is informational only — Homebrew tracks upstream automatically.
VERSION="3.4.0"

# Cask names: each is `font-<name>-nerd-font`.
FONTS=(
    font-fira-code-nerd-font
    font-jetbrains-mono-nerd-font
    font-hack-nerd-font
    font-meslo-lg-nerd-font
    font-caskaydia-cove-nerd-font
)

for font in "${FONTS[@]}"; do
    brew install --cask "$font"
done

echo "Nerd Fonts installed (target version $VERSION; brew may have a newer one)."
