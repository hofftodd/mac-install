#!/usr/bin/env bash
set -euo pipefail

# Posting, API client (HTTP requests, collections, environments) for the
# terminal. Homebrew's formula bundles its own Python. See
# https://posting.sh and https://github.com/darrenburns/posting
brew install posting

echo "posting installed: $(brew list --versions posting)"
