#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"
require_macos

# Dock and Spaces. Each setting is proposed separately; answer y to apply.
echo "macOS settings: Dock and Spaces"

propose "Automatically hide the Dock" \
    com.apple.dock autohide bool true
propose "Show the hidden Dock immediately, with no delay" \
    com.apple.dock autohide-delay float 0
propose "Smaller Dock icons (48 px)" \
    com.apple.dock tilesize int 48
propose "Don't show recently used apps in the Dock" \
    com.apple.dock show-recents bool false
propose "Keep Spaces in a fixed order (don't rearrange by most recent use)" \
    com.apple.dock mru-spaces bool false

macos_settings_done Dock
