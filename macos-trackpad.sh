#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"

# macOS settings: trackpad. Each setting is written for both the built-in and
# Bluetooth (Magic) trackpads.
# Run with no arguments to be asked about each setting, with setting ids to
# apply just those, or with --list to see the ids. install-master.sh shows each
# setting as its own checkbox.

setting tap-to-click "Tap to click" \
    com.apple.AppleMultitouchTrackpad Clicking bool true \
    com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking bool true \
    currentHost:NSGlobalDomain com.apple.mouse.tapBehavior int 1
# Three-finger drag takes over three-finger swipes, so (like System Settings
# does) this also turns off the three-finger swipe gestures; swipe between
# Spaces with four fingers instead.
setting three-finger-drag "Three-finger drag (swipes move to 4 fingers)" \
    com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag bool true \
    com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag bool true \
    com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture int 0 \
    com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture int 0 \
    com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture int 0 \
    com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture int 0

run_settings "$@"
macos_settings_done
echo "Trackpad changes take effect after you log out and back in."
