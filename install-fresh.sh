#!/usr/bin/env bash
set -euo pipefail

# fresh, terminal text editor: easy, powerful and fast. See https://sinelaw.github.io/fresh/
# Formula was renamed from `fresh` to `fresh-editor`; unlink the old name if present
# so the new bottle can take over /opt/homebrew/bin/fresh.
if brew list --formula fresh &>/dev/null; then
    brew unlink --formula fresh
    brew uninstall --formula fresh
fi

brew install fresh-editor
brew link --overwrite fresh-editor

echo "fresh installed: $(brew list --versions fresh-editor)"
