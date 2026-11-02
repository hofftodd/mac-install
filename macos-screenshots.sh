#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"
require_macos

# Screenshots. Each setting is proposed separately; answer y to apply.
echo "macOS settings: screenshots"

SCREENSHOT_DIR="${SCREENSHOT_DIR:-$HOME/Screenshots}"

propose "Save screenshots to $SCREENSHOT_DIR instead of the Desktop" \
    com.apple.screencapture location string "$SCREENSHOT_DIR"
# Create the folder only if screenshots now go there.
if [ "$(defaults read com.apple.screencapture location 2>/dev/null || true)" = "$SCREENSHOT_DIR" ]; then
    mkdir -p "$SCREENSHOT_DIR"
fi
propose "Save screenshots as PNG" \
    com.apple.screencapture type string png
propose "Leave out the drop shadow on window screenshots" \
    com.apple.screencapture disable-shadow bool true

macos_settings_done SystemUIServer
