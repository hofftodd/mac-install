#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"

# macOS settings: screenshots.
# Run with no arguments to be asked about each setting, with setting ids to
# apply just those, or with --list to see the ids. install-master.sh shows each
# setting as its own checkbox.

SCREENSHOT_DIR="${SCREENSHOT_DIR:-$HOME/Screenshots}"

setting location "Save screenshots to ${SCREENSHOT_DIR/#"$HOME"/\~}" \
    com.apple.screencapture location string "$SCREENSHOT_DIR"
setting png "Screenshot format: PNG" \
    com.apple.screencapture type string png
setting no-shadow "No shadow on window screenshots" \
    com.apple.screencapture disable-shadow bool true

run_settings "$@"
# Create the folder if screenshots now go there.
if [ "$(defaults read com.apple.screencapture location 2>/dev/null || true)" = "$SCREENSHOT_DIR" ]; then
    mkdir -p "$SCREENSHOT_DIR"
fi
macos_settings_done SystemUIServer
