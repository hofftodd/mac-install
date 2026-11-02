#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"

# Ollama. See https://ollama.com/
# The macOS distribution is a .app cask that includes the CLI and a launchd
# agent for the local server.
cask_install ollama-app "Ollama.app"

echo "Ollama installed. Try: ollama run llama3.2"
echo "Launch the Ollama app once to start the background service."
