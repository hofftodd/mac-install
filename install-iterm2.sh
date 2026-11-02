#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# iTerm2, feature-rich terminal emulator for macOS. See https://iterm2.com/
cask_install iterm2 "iTerm.app"

echo "iTerm2 installed."
