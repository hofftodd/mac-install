#!/usr/bin/env bash
set -euo pipefail

# Tailscale (the macOS app, which bundles the daemon and menu-bar UI).
# See https://tailscale.com/download/mac
brew install --cask tailscale-app

echo "Tailscale installed. Launch it from Applications and sign in."
