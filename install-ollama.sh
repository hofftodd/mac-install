#!/usr/bin/env bash
set -euo pipefail

# Ollama. See https://ollama.com/
# The macOS distribution is a .app cask that includes the CLI and a launchd
# agent for the local server.
brew install --cask ollama-app

echo "Ollama installed. Try: ollama run llama3.2"
echo "Launch the Ollama app once to start the background service."
