#!/usr/bin/env bash
set -euo pipefail

# lazydocker, terminal UI for Docker and Docker Compose. Works with whichever
# Docker provider is running (OrbStack, Docker Desktop, Rancher Desktop).
# See https://github.com/jesseduffield/lazydocker
brew install lazydocker

echo "lazydocker installed: $(lazydocker --version | head -1)"
