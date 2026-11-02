#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"
require_macos

# Finder. Each setting is proposed separately; answer y to apply.
echo "macOS settings: Finder"

propose "Show all file extensions" \
    NSGlobalDomain AppleShowAllExtensions bool true
propose "Show hidden files (dotfiles); you can still toggle with Cmd+Shift+." \
    com.apple.finder AppleShowAllFiles bool true
propose "Show the path bar at the bottom of Finder windows" \
    com.apple.finder ShowPathbar bool true
propose "Show the status bar (item count and free space)" \
    com.apple.finder ShowStatusBar bool true
propose "Use list view in new Finder windows" \
    com.apple.finder FXPreferredViewStyle string Nlsv
propose "Keep folders above files when sorting by name" \
    com.apple.finder _FXSortFoldersFirst bool true
propose "Search the current folder by default (instead of the whole Mac)" \
    com.apple.finder FXDefaultSearchScope string SCcf
propose "Don't warn when changing a file extension" \
    com.apple.finder FXEnableExtensionChangeWarning bool false
propose "Don't create .DS_Store files on network drives" \
    com.apple.desktopservices DSDontWriteNetworkStores bool true
propose "Don't create .DS_Store files on USB drives" \
    com.apple.desktopservices DSDontWriteUSBStores bool true

macos_settings_done Finder
