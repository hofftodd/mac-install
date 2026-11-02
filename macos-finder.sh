#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"

# macOS settings: Finder.
# Run with no arguments to be asked about each setting, with setting ids to
# apply just those, or with --list to see the ids. install-master.sh shows each
# setting as its own checkbox.

setting show-extensions "Show all file extensions" \
    NSGlobalDomain AppleShowAllExtensions bool true
setting show-hidden "Show hidden files (Cmd+Shift+. toggles)" \
    com.apple.finder AppleShowAllFiles bool true
setting path-bar "Show path bar" \
    com.apple.finder ShowPathbar bool true
setting status-bar "Show status bar" \
    com.apple.finder ShowStatusBar bool true
setting list-view "New windows use list view" \
    com.apple.finder FXPreferredViewStyle string Nlsv
setting folders-first "Folders above files when sorting" \
    com.apple.finder _FXSortFoldersFirst bool true
setting search-current-folder "Search the current folder by default" \
    com.apple.finder FXDefaultSearchScope string SCcf
setting no-extension-warning "No warning when changing an extension" \
    com.apple.finder FXEnableExtensionChangeWarning bool false
setting no-ds-store-network "No .DS_Store files on network drives" \
    com.apple.desktopservices DSDontWriteNetworkStores bool true
setting no-ds-store-usb "No .DS_Store files on USB drives" \
    com.apple.desktopservices DSDontWriteUSBStores bool true

run_settings "$@"
macos_settings_done Finder
