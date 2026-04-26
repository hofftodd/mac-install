#!/usr/bin/env bash
set -euo pipefail

# micro, modern terminal text editor. See https://micro-editor.github.io/
brew install micro

echo "micro installed: $(micro --version | head -1)"
