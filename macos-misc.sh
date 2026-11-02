#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"
require_macos

# Save/Print dialogs, Time Machine and Photos. Each setting is proposed
# separately; answer y to apply.
echo "macOS settings: dialogs and devices"

propose "Open Save dialogs fully expanded (with the folder browser)" \
    NSGlobalDomain NSNavPanelExpandedStateForSaveMode bool true \
    NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 bool true
propose "Open Print dialogs fully expanded" \
    NSGlobalDomain PMPrintingExpandedStateForPrint bool true \
    NSGlobalDomain PMPrintingExpandedStateForPrint2 bool true
propose "Don't ask to use every new disk for Time Machine backups" \
    com.apple.TimeMachine DoNotOfferNewDisksForBackup bool true
propose "Don't open Photos when an iPhone, iPad or camera is plugged in" \
    currentHost:com.apple.ImageCapture disableHotPlug bool true

macos_settings_done
echo "Some apps pick up these changes only after they are restarted."
