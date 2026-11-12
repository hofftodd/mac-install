#!/usr/bin/env bash
set -euo pipefail

# lazygit, terminal UI for git. See https://github.com/jesseduffield/lazygit
brew install lazygit

echo "lazygit installed: $(lazygit --version | head -1)"
