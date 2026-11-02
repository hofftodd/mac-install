#!/usr/bin/env bash
set -euo pipefail

# croft, VSCode-style terminal text editor written in Rust. See https://github.com/vitali87/croft
# Installed from the project's Homebrew tap (prebuilt binary, no Rust toolchain needed).
brew install vitali87/croft/croft

echo "croft installed: $(brew list --versions croft)"
echo "Tips:"
echo "  - Use a Nerd Font in your terminal (see install-nerd-fonts.sh) or icons render as boxes."
echo "  - Run 'croft setup-iterm2' or 'croft setup-ghostty' to enable Cmd-key shortcuts."
echo "  - Upgrade with 'brew upgrade croft'."
