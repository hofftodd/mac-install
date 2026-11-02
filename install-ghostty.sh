#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Ghostty, fast GPU-accelerated native terminal emulator. See https://ghostty.org/
cask_install ghostty "Ghostty.app"

echo "Ghostty installed."
echo "Config file: ~/.config/ghostty/config (run 'ghostty +show-config --default --docs' for options)"
