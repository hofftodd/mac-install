#!/usr/bin/env bash
set -euo pipefail

# GitHub CLI. See https://cli.github.com/
brew install gh

echo "GitHub CLI installed: $(gh --version | head -1)"
echo "Run: gh auth login"
