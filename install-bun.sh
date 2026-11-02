#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Bun: fast JavaScript/TypeScript runtime, package manager, bundler and test
# runner. Works alongside Node (install-nodejs.sh); it doesn't need it.
# See https://bun.com/
#
# Installed from Homebrew so `brew upgrade` keeps it current (Bun's docs say to
# use `brew upgrade bun` rather than `bun upgrade` for Homebrew installs).
# Homebrew also installs the zsh completions.
if [ -x "$HOME/.bun/bin/bun" ] && ! brew list --formula bun >/dev/null 2>&1; then
    echo "Note: Bun is also installed by its own installer at ~/.bun/bin/bun."
    echo "      The Homebrew copy will be used; to remove the other: rm -rf ~/.bun/bin/bun"
fi
brew install bun

# Global packages (`bun add -g <pkg>`) put their commands in ~/.bun/bin.
install_zshrc_snippet 20-bun <<'SNIPPET'
export PATH="$PATH:$HOME/.bun/bin"
SNIPPET

echo
echo "Bun installed: $(bun --version)"
echo "Restart your shell or run: source ~/.zshrc"
echo "Quick reference:"
echo "  bun install / bun add <pkg>   — install dependencies (reads package.json)"
echo "  bun run <script|file.ts>      — run a package.json script or a TS/JS file"
echo "  bunx <pkg>                    — run a package's CLI without installing it"
echo "  bun test                      — run tests"
echo "  brew upgrade bun              — update Bun"
