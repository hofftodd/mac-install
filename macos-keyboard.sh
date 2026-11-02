#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/macos-defaults.sh"
require_macos

# Keyboard and text input. Each setting is proposed separately; answer y to apply.
echo "macOS settings: keyboard and text input"

propose "Fast key repeat (the fastest rate System Settings allows)" \
    NSGlobalDomain KeyRepeat int 2
propose "Short delay before a held key starts repeating" \
    NSGlobalDomain InitialKeyRepeat int 15
propose "Holding a key repeats it instead of showing the accent picker (useful for Vim keys)" \
    NSGlobalDomain ApplePressAndHoldEnabled bool false
propose "Turn off smart quotes (stops \" becoming curly quotes when typing code)" \
    NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled bool false
propose "Turn off smart dashes (stops -- becoming an em dash)" \
    NSGlobalDomain NSAutomaticDashSubstitutionEnabled bool false
propose "Turn off automatic capitalisation" \
    NSGlobalDomain NSAutomaticCapitalizationEnabled bool false
propose "Turn off automatic spelling correction" \
    NSGlobalDomain NSAutomaticSpellingCorrectionEnabled bool false
propose "Turn off adding a period when you type two spaces" \
    NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled bool false

macos_settings_done
echo "Key repeat changes take effect after you log out and back in."
