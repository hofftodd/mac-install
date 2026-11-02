# shellcheck shell=bash
# Shared helper for install scripts that need shell setup in zsh.
#
# Instead of appending blocks to ~/.zshrc, each tool gets its own file in
# ~/.zshrc.d/ (e.g. ~/.zshrc.d/20-nvm.zsh). ~/.zshrc gets a small loader,
# added once, that sources every ~/.zshrc.d/*.zsh in name order — so the
# numeric prefix controls load order. To drop a tool's shell setup, delete
# its file.
#
# Usage, from an install script:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"
#   install_zshrc_snippet 20-nvm <<'EOF'
#   export NVM_DIR="$HOME/.nvm"
#   ...
#   EOF
#
# Bash 3.2 compatible (macOS /bin/bash).

ZSHRC="${ZSHRC:-$HOME/.zshrc}"
ZSHRC_D="${ZSHRC_D:-$HOME/.zshrc.d}"
ZSHRC_LOADER_BEGIN='# >>> mac-install: load ~/.zshrc.d >>>'
ZSHRC_LOADER_END='# <<< mac-install: load ~/.zshrc.d <<<'

# Create ~/.zshrc.d and append the loader to ~/.zshrc if it isn't there yet.
ensure_zshrc_loader() {
    mkdir -p "$ZSHRC_D"
    _write_base_snippet
    if ! grep -qF "$ZSHRC_LOADER_BEGIN" "$ZSHRC" 2>/dev/null; then
        # shellcheck disable=SC2094  # append mode doesn't truncate, so tail reads the old contents
        {
            # Separate from existing content (finishing an unterminated last line first).
            if [ -s "$ZSHRC" ]; then
                if [ -n "$(tail -c 1 "$ZSHRC")" ]; then echo; fi
                echo
            fi
            echo "$ZSHRC_LOADER_BEGIN"
            # shellcheck disable=SC2016  # written literally for zsh to expand
            echo 'for f in ~/.zshrc.d/*.zsh(N); do source "$f"; done; unset f'
            echo "$ZSHRC_LOADER_END"
        } >> "$ZSHRC"
        echo "Added ~/.zshrc.d loader to ~/.zshrc"
    fi
}

# _write_base_snippet — ~/.zshrc.d/00-base.zsh, loaded before every other
# snippet. Rewritten each time a script installs a snippet, so updates to it
# reach existing machines.
_write_base_snippet() {
    cat > "$ZSHRC_D/00-base.zsh" <<'EOF'
# Managed by mac-install (lib/zshrc.sh). Rewritten whenever an install script runs.

# Keep PATH free of duplicates (nested shells would otherwise keep prepending).
typeset -U path PATH

# Tab completion. macOS's default zsh doesn't turn it on, so completions that
# Homebrew installs (gh, bun, rustup, starship, ...) and the ones later
# snippets register (uv) would never load. Skipped if your own ~/.zshrc
# already ran compinit before this point.
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
    if [[ -d /opt/homebrew ]]; then HOMEBREW_PREFIX=/opt/homebrew; else HOMEBREW_PREFIX=/usr/local; fi
fi
if [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
    fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi
if ! (( $+functions[compdef] )); then
    # -i: don't stop to ask about group-writable directories; if Homebrew's are
    # flagged, fix them with: chmod -R go-w "$HOMEBREW_PREFIX/share"
    autoload -Uz compinit && compinit -i
fi
EOF
}

# Remove exact lines (read from the file given as $1) from ~/.zshrc. Older
# versions of these scripts appended snippet lines straight to ~/.zshrc; this
# migrates them so nothing is loaded twice. Lines that don't match exactly
# are left alone. Backs ~/.zshrc up once, before the first change.
remove_legacy_zshrc_lines() {
    local lines_file="$1" tmp
    [ -f "$ZSHRC" ] || return 0
    tmp="$(mktemp)"
    # Skip blank lines in the list so we never strip blank lines from ~/.zshrc.
    awk 'NR == FNR { if ($0 != "") drop[$0] = 1; next } !($0 in drop)' \
        "$lines_file" "$ZSHRC" > "$tmp"
    if ! cmp -s "$ZSHRC" "$tmp"; then
        if [ ! -e "$ZSHRC.mac-install.bak" ]; then
            cp "$ZSHRC" "$ZSHRC.mac-install.bak"
            echo "Backed up ~/.zshrc to ~/.zshrc.mac-install.bak"
        fi
        # Overwrite in place (not mv) so a symlinked ~/.zshrc stays a symlink.
        cat "$tmp" > "$ZSHRC"
        echo "Moved old setup lines out of ~/.zshrc"
    fi
    rm -f "$tmp"
}

# install_zshrc_snippet <name>  (snippet body on stdin)
# Writes ~/.zshrc.d/<name>.zsh, replacing any previous version, and removes
# the same lines from ~/.zshrc if an older script put them there.
install_zshrc_snippet() {
    local name="$1" body
    body="$(mktemp)"
    cat > "$body"

    # Migrate first, so the one-time backup is the untouched original.
    remove_legacy_zshrc_lines "$body"
    ensure_zshrc_loader

    {
        echo "# Managed by mac-install ($(basename "$0")). Re-running that script overwrites this file."
        cat "$body"
    } > "$ZSHRC_D/$name.zsh"
    rm -f "$body"
    echo "Wrote ~/.zshrc.d/$name.zsh"
}
