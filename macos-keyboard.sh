#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"

# macOS settings: keyboard and text input.
# Run with no arguments to be asked about each setting, with setting ids to
# apply just those, or with --list to see the ids. install-master.sh shows each
# setting as its own checkbox.

setting key-repeat "Key repeat rate: fastest (2)" \
    NSGlobalDomain KeyRepeat int 2
setting key-repeat-delay "Delay until key repeat: shortest (15)" \
    NSGlobalDomain InitialKeyRepeat int 15
setting press-and-hold "Held keys repeat (no accent picker)" \
    NSGlobalDomain ApplePressAndHoldEnabled bool false
setting smart-quotes "Smart quotes: off" \
    NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled bool false
setting smart-dashes "Smart dashes: off" \
    NSGlobalDomain NSAutomaticDashSubstitutionEnabled bool false
setting auto-capitalise "Auto-capitalisation: off" \
    NSGlobalDomain NSAutomaticCapitalizationEnabled bool false
setting auto-correct "Auto-correct: off" \
    NSGlobalDomain NSAutomaticSpellingCorrectionEnabled bool false
setting double-space-period "Double-space inserts period: off" \
    NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled bool false

run_settings "$@"
macos_settings_done
echo "Key repeat changes take effect after you log out and back in."
