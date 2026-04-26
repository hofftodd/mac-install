#!/usr/bin/env bash
set -euo pipefail

# Install a current Python via Homebrew. macOS ships an old system Python
# that you shouldn't use directly; brew gives you a sane default `python3`.
brew install python

echo "Python installed: $(python3 --version)"
echo "pip: $(pip3 --version)"
