#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# Language servers (LSP) for the languages this repo sets up, plus common
# config/doc formats. Editors that speak LSP use them for completion,
# diagnostics, go-to-definition, hover, rename and formatting.
#
# Fresh ships settings for all of these, but only uses a server that's on
# PATH, and by default doesn't start one by itself — so this also turns on
# auto_start for each installed server in ~/.config/fresh/config.json
# (only adding what isn't set; your own settings are never overwritten).
#
#   Rust          rust-analyzer          rustup (install-rust.sh)
#   Go            gopls                  Homebrew
#   Python        pylsp + ruff plugin    uv tool (install-uv.sh)
#   TS / JS       typescript-language-server   Homebrew
#   HTML/CSS/JSON vscode-langservers-extracted Homebrew
#   Shell         bash-language-server   Homebrew
#   YAML / TOML   yaml-language-server, taplo  Homebrew
#   Markdown      marksman               pinned GitHub release (Homebrew's needs .NET)
#   Java          jdtls                  Homebrew
#   SQL           sqls                   go install, pinned (not in Homebrew)
#   C / C++       clangd                 Xcode Command Line Tools (already installed)
SQLS_VERSION="${SQLS_VERSION:-v0.2.48}"
MARKSMAN_VERSION="${MARKSMAN_VERSION:-2026-02-08}"
MARKSMAN_SHA256="6a801c17b5ac0dba69787c5282b3b3bd416e66c96253fae098d311c6bbd1833b"

ensure_brew_on_path
LOCAL_BIN="$HOME/.local/bin"
export GOPATH="${GOPATH:-$HOME/go}"
# Make servers installed by this and other scripts findable below.
export PATH="$LOCAL_BIN:$GOPATH/bin:$HOME/.cargo/bin:$PATH"
mkdir -p "$LOCAL_BIN"
install_zshrc_snippet 10-local-bin <<'SNIPPET'
export PATH="$HOME/.local/bin:$PATH"
SNIPPET

# --- Homebrew --------------------------------------------------------------------
brew install gopls typescript-language-server vscode-langservers-extracted bash-language-server yaml-language-server taplo jdtls

# --- Python: pylsp (Fresh's default Python server) via uv -------------------------
if command -v uv >/dev/null 2>&1; then
    uv tool install python-lsp-server --with python-lsp-ruff
else
    echo "uv not found — skipping pylsp. Run install-uv.sh, then re-run this script."
fi

# --- Rust: rust-analyzer comes with rustup ----------------------------------------
if ! command -v rust-analyzer >/dev/null 2>&1 && command -v rustup >/dev/null 2>&1; then
    rustup component add rust-analyzer
fi
command -v rust-analyzer >/dev/null 2>&1 || echo "rust-analyzer not found — run install-rust.sh, then re-run this script."

# --- SQL: sqls (not in Homebrew), pinned ------------------------------------------
if command -v go >/dev/null 2>&1; then
    go install "github.com/sqls-server/sqls@${SQLS_VERSION}"
else
    echo "go not found — skipping sqls. Run install-go.sh, then re-run this script."
fi

# --- Markdown: marksman from its pinned GitHub release, checksum-verified ---------
marksman_sha() { shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1; }
if [ -x "$LOCAL_BIN/marksman" ] && [ "$(marksman_sha "$LOCAL_BIN/marksman")" = "$MARKSMAN_SHA256" ]; then
    echo "marksman $MARKSMAN_VERSION is already installed."
else
    TMP="$(mktemp)"
    curl -fsSL -o "$TMP" "https://github.com/artempyanykh/marksman/releases/download/${MARKSMAN_VERSION}/marksman-macos"
    if [ "$(marksman_sha "$TMP")" != "$MARKSMAN_SHA256" ]; then
        rm -f "$TMP"
        echo "marksman download doesn't match the pinned checksum — not installing it." >&2
        exit 1
    fi
    chmod +x "$TMP"
    mv -f "$TMP" "$LOCAL_BIN/marksman"
    echo "Installed marksman $MARKSMAN_VERSION to $LOCAL_BIN/marksman"
fi

# --- C/C++: clangd ships with the Xcode Command Line Tools ------------------------
if ! command -v clangd >/dev/null 2>&1; then
    if CLANGD="$(xcrun --find clangd 2>/dev/null)" && [ -x "$CLANGD" ]; then
        ln -sf "$CLANGD" "$LOCAL_BIN/clangd"
        echo "Linked clangd from the Command Line Tools into $LOCAL_BIN"
    else
        echo "clangd not found. For C/C++ support: brew install llvm (and add its bin to PATH)."
    fi
fi

# --- Fresh: auto-start the servers that are installed -----------------------------
# Fresh language id → the server command it runs for it.
LSP_MAP="rust=rust-analyzer go=gopls python=pylsp javascript=typescript-language-server
typescript=typescript-language-server html=vscode-html-language-server
css=vscode-css-language-server json=vscode-json-language-server
jsonc=vscode-json-language-server bash=bash-language-server
yaml=yaml-language-server toml=taplo markdown=marksman java=jdtls sql=sqls
c=clangd cpp=clangd"

INSTALLED=""
echo
echo "Language servers:"
for pair in $LSP_MAP; do
    lang="${pair%%=*}" cmd="${pair#*=}"
    if command -v "$cmd" >/dev/null 2>&1; then
        INSTALLED="$INSTALLED $lang"
        printf '  ✓ %-11s %s\n' "$lang" "$cmd"
    else
        printf '  ✗ %-11s %s (not found)\n' "$lang" "$cmd"
    fi
done

FRESH_CONFIG="$HOME/.config/fresh/config.json"
mkdir -p "$(dirname "$FRESH_CONFIG")"
# shellcheck disable=SC2086  # INSTALLED is a space-separated list
python3 -I - "$FRESH_CONFIG" $INSTALLED <<'PY'
import json, os, shutil, sys

path, langs = sys.argv[1], sys.argv[2:]
config = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            config = json.load(f)
    except ValueError:
        print(f"\n{path} isn't plain JSON (comments?) — left unchanged.")
        print('Turn on auto-start yourself: "lsp": {"<language>": {"auto_start": true}}, or use')
        print('"Start <server> (always)" in Fresh\'s LSP status popup.')
        sys.exit(0)

lsp = config.setdefault("lsp", {})
added = []
for lang in langs:
    entry = lsp.get(lang)
    if entry is None:
        lsp[lang] = {"auto_start": True}
        added.append(lang)
    elif isinstance(entry, dict) and "auto_start" not in entry:
        entry["auto_start"] = True
        added.append(lang)
    # A list (several servers) or an explicit auto_start is yours: left alone.

if not added:
    print(f"\nFresh: auto-start already configured in {path}")
    sys.exit(0)
if os.path.exists(path) and not os.path.exists(path + ".mac-install.bak"):
    shutil.copy2(path, path + ".mac-install.bak")
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
print(f"\nFresh: turned on auto-start for {', '.join(added)} in {path}")
PY

echo
echo "In Fresh, open a project and trust it when asked — language servers only run"
echo "in trusted workspaces. The LSP indicator in the status bar shows each server."
