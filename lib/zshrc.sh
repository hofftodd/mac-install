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
