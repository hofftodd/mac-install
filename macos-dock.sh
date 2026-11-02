#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"

# macOS settings: Dock and Spaces.
# Run with no arguments to be asked about each setting, with setting ids to
# apply just those, or with --list to see the ids. install-master.sh shows each
# setting as its own checkbox.

setting autohide "Auto-hide the Dock" \
    com.apple.dock autohide bool true
setting autohide-delay "Hidden Dock appears instantly (no delay)" \
    com.apple.dock autohide-delay float 0
setting tilesize "Dock icon size: 48 px" \
    com.apple.dock tilesize int 48
setting no-recents "No recent apps in the Dock" \
    com.apple.dock show-recents bool false
setting fixed-spaces "Spaces stay in a fixed order" \
    com.apple.dock mru-spaces bool false

run_settings "$@"
macos_settings_done Dock
