#!/usr/bin/env bash
set -euo pipefail

# Unison: bidirectional file synchronizer. https://www.cis.upenn.edu/~bcpierce/unison/
brew install unison

echo "Unison installed: $(unison -version | head -1)"
