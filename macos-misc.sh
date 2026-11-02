#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"

# macOS settings: Save/Print dialogs, Time Machine and Photos.
# Run with no arguments to be asked about each setting, with setting ids to
# apply just those, or with --list to see the ids. install-master.sh shows each
# setting as its own checkbox.

setting expand-save "Save dialogs open expanded" \
    NSGlobalDomain NSNavPanelExpandedStateForSaveMode bool true \
    NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 bool true
setting expand-print "Print dialogs open expanded" \
    NSGlobalDomain PMPrintingExpandedStateForPrint bool true \
    NSGlobalDomain PMPrintingExpandedStateForPrint2 bool true
setting no-timemachine-prompt "Time Machine doesn't offer new disks" \
    com.apple.TimeMachine DoNotOfferNewDisksForBackup bool true
setting no-photos-autoopen "Photos doesn't open for phones/cameras" \
    currentHost:com.apple.ImageCapture disableHotPlug bool true

run_settings "$@"
macos_settings_done
echo "Some apps pick up these changes only after they are restarted."
