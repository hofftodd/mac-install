#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"
require_macos

# Trackpad. Each setting is proposed separately; answer y to apply.
# Each one is written for both the built-in and Bluetooth (Magic) trackpads.
echo "macOS settings: trackpad"

propose "Tap to click" \
    com.apple.AppleMultitouchTrackpad Clicking bool true \
    com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking bool true \
    currentHost:NSGlobalDomain com.apple.mouse.tapBehavior int 1
# Three-finger drag takes over three-finger swipes, so (like System Settings
# does) this also turns off the three-finger swipe gestures; use four fingers
# to swipe between Spaces instead.
propose "Three-finger drag (moves the Spaces/App Exposé swipes to four fingers)" \
    com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag bool true \
    com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag bool true \
    com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture int 0 \
    com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture int 0 \
    com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture int 0 \
    com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture int 0

macos_settings_done
echo "Trackpad changes take effect after you log out and back in."
