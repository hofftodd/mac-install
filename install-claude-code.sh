#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Install Claude Code, Anthropic's official CLI.
# See https://docs.claude.com/en/docs/claude-code/setup
curl -fsSL https://claude.ai/install.sh | bash

# The installer drops the binary at ~/.local/bin/claude — make sure that's on PATH.
install_zshrc_snippet 10-local-bin <<'EOF'
export PATH="$HOME/.local/bin:$PATH"
EOF

# Start every `claude` session with Remote Control on, so it can be picked up
# from claude.ai or the phone app. Merged into ~/.claude/settings.json without
# touching other keys; a file that isn't valid JSON is left alone.
CLAUDE_SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
/usr/bin/python3 -I - "$CLAUDE_SETTINGS" <<'PY'
import json, os, sys
path = sys.argv[1]
def skip(why):
    print(f"  Warning: {path} {why}; not adding remoteControlAtStartup.", file=sys.stderr)
    sys.exit(0)
settings = {}
if os.path.exists(path) and os.path.getsize(path) > 0:
    try:
        with open(path) as f:
            settings = json.load(f)
    except ValueError as e:
        skip(f"isn't valid JSON ({e})")
if not isinstance(settings, dict):
    skip("isn't a JSON object")
if settings.get("remoteControlAtStartup") is True:
    print("  Remote Control at startup: already on")
    sys.exit(0)
settings["remoteControlAtStartup"] = True
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
print(f"  Remote Control at startup: on ({path})")
PY

echo "Claude Code installed. Restart your shell or run: source ~/.zshrc"
echo "Then run: claude   (first launch will prompt you to authenticate)"
