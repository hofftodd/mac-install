#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source lib/brew.sh

# Status check for everything mac-install sets up: what's installed (and which
# version), what isn't, and what's installed but broken — plus a few health
# checks (PATH, shell setup, Homebrew).
#
#   ./doctor.sh            full report
#   ./doctor.sh --no-brew  skip `brew doctor` (it takes a few seconds)
#
# Tools are looked up on the PATH a new terminal gets (read once from an
# interactive zsh), so anything set up through ~/.zshrc.d is found the same
# way your shell finds it.
#
#   ✓ installed   – not installed   ! worth a look   ✗ broken
# Exit status is 1 if anything is ✗, else 0.
RUN_BREW_DOCTOR=1
[ "${1:-}" = "--no-brew" ] && RUN_BREW_DOCTOR=0

ensure_brew_on_path
# The PATH a new terminal would have.
if command -v zsh >/dev/null 2>&1; then
    SHELL_PATH="$(zsh -i -l -c 'print -r -- "__PATH__=$PATH"' 2>/dev/null </dev/null | sed -n 's/^__PATH__=//p' | tail -1 || true)"
    [ -n "$SHELL_PATH" ] && export PATH="$SHELL_PATH"
fi

BROKEN=0
ok() { printf '  ✓ %-34s %s\n' "$1" "${2:-}"; }
missing() { printf '  – %-34s %s\n' "$1" "${2:-not installed}"; }
warn() { printf '  ! %-34s %s\n' "$1" "$2"; }
broken() {
    printf '  ✗ %-34s %s\n' "$1" "$2"
    BROKEN=1
}

# First line of a command's version output, trimmed.
version_of() { "$@" 2>&1 </dev/null | head -1 | cut -c1-60 || true; }

app_path() {
    local d
    for d in /Applications "$HOME/Applications"; do
        [ -e "$d/$1" ] && { echo "$d/$1"; return 0; }
    done
    return 1
}

app_version() {
    defaults read "$1/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "installed"
}

# --- Checks for scripts that need more than "app exists" / "command on PATH" ---

check_git_config() {
    local name email
    name="$(git config --global user.name 2>/dev/null || true)"
    email="$(git config --global user.email 2>/dev/null || true)"
    if [ -z "$name" ] || [ -z "$email" ]; then
        missing "$1" "git user.name/user.email not set"
    elif [ "$(git config --global core.pager 2>/dev/null || true)" != delta ]; then
        warn "$1" "$name <$email>, but delta isn't the pager"
    else
        ok "$1" "$name <$email>"
    fi
}

check_sdkman() {
    [ -d "$HOME/.sdkman" ] || { missing "$1"; return; }
    case "$(command -v java || true)" in
        "$HOME/.sdkman/"*) ok "$1" "$(version_of java -version)" ;;
        "") broken "$1" "SDKMAN is installed but java isn't on PATH" ;;
        *) broken "$1" "java is $(command -v java), not SDKMAN's (run install-sdkman.sh)" ;;
    esac
}

check_uv() {
    command -v uv >/dev/null 2>&1 || { missing "$1"; return; }
    if [ "$(command -v python3 || true)" = "$HOME/.local/bin/python3" ]; then
        ok "$1" "$(version_of uv --version); $(version_of python3 --version)"
    else
        broken "$1" "python3 is $(command -v python3 || echo missing), not uv's ~/.local/bin/python3"
    fi
}

check_node() {
    [ -d "$HOME/.nvm" ] || { missing "$1"; return; }
    case "$(command -v node || true)" in
        "$HOME/.nvm/"*) ok "$1" "node $(version_of node --version) (nvm)" ;;
        "") broken "$1" "nvm is installed but node isn't on PATH" ;;
        *) warn "$1" "node is $(command -v node), not nvm's" ;;
    esac
}

check_postgres() {
    command -v psql >/dev/null 2>&1 || { missing "$1"; return; }
    if command -v pg_isready >/dev/null 2>&1 && pg_isready -q 2>/dev/null; then
        ok "$1" "$(version_of psql --version), server running"
    else
        warn "$1" "$(version_of psql --version), but the server isn't answering (brew services list)"
    fi
}

check_language_servers() {
    local s found=0 total=0 absent=""
    for s in rust-analyzer gopls pylsp typescript-language-server vscode-json-language-server \
        bash-language-server yaml-language-server taplo marksman jdtls sqls clangd; do
        total=$((total + 1))
        if command -v "$s" >/dev/null 2>&1; then found=$((found + 1)); else absent="$absent $s"; fi
    done
    if [ "$found" -eq 0 ]; then
        missing "$1"
    elif [ "$found" -lt "$total" ]; then
        warn "$1" "$found/$total on PATH; missing:$absent"
    else
        ok "$1" "$found/$total language servers on PATH"
    fi
}

check_dwarfstar() {
    local dir="${DS4_DIR:-$HOME/src/ds4}"
    if [ ! -d "$dir/.git" ]; then missing "$1"
    elif [ ! -x "$dir/ds4" ]; then broken "$1" "$dir exists but isn't built (re-run install-dwarfstar.sh)"
    elif ! command -v ds4 >/dev/null 2>&1; then broken "$1" "built, but the ds4 wrapper isn't on PATH (re-run install-dwarfstar.sh)"
    else
        local models
        # gguf/ only exists once a model has been downloaded.
        models="$(find "$dir/gguf" -name '*.gguf' 2>/dev/null | wc -l | tr -d ' ' || true)"
        ok "$1" "built $(git -C "$dir" log -1 --format='%h, %cs'); $models model file(s) in gguf/"
    fi
}

check_modern_cli() {
    local c found=0 total=0 absent=""
    for c in rg fd bat eza fzf zoxide delta jq yq tree htop ncdu; do
        total=$((total + 1))
        if command -v "$c" >/dev/null 2>&1; then found=$((found + 1)); else absent="$absent $c"; fi
    done
    if [ "$found" -eq 0 ]; then missing "$1"
    elif [ "$found" -lt "$total" ]; then warn "$1" "$found/$total installed; missing:$absent"
    else ok "$1" "$found/$total tools"; fi
}

check_nerd_fonts() {
    local n
    n="$(brew list --cask 2>/dev/null | grep -c -- '-nerd-font$' || true)"
    if [ "$n" -gt 0 ]; then ok "$1" "$n Nerd Fonts"; else missing "$1"; fi
}

check_zsh_plugins() {
    local f="$HOME/.zshrc.d/99-zsh-plugins.zsh"
    if [ ! -f "$f" ]; then missing "$1"
    elif brew list zsh-autosuggestions zsh-syntax-highlighting direnv >/dev/null 2>&1; then
        ok "$1" "autosuggestions, syntax highlighting, direnv"
    else
        broken "$1" "$f exists but the Homebrew packages are missing (run install-zsh-plugins.sh)"
    fi
}

check_versions_file() {
    if [ -f "$HOME/.mac-install/versions.env" ]; then
        ok "$1" "last run $(sed -n 's/^# Written by .* on \(.*\)\.$/\1/p' "$HOME/.mac-install/versions.env")"
    else
        missing "$1" "never run (scripts use built-in defaults)"
    fi
}

# --- What each install script provides ----------------------------------------
# script|check, where check is: app:<Name>.app, cmd:<command>[:<version args>],
# brew:<formula>, npm:<global package>, or fn:<function>. tests/check-menu.sh makes sure every install script is here.
CHECKS='update-versions.sh|fn:check_versions_file
install-git-config.sh|fn:check_git_config
install-gh.sh|cmd:gh
install-sdkman.sh|fn:check_sdkman
install-uv.sh|fn:check_uv
install-go.sh|cmd:go:version
install-rust.sh|cmd:rustc
install-nodejs.sh|fn:check_node
install-bun.sh|cmd:bun
install-ollama.sh|app:Ollama.app
install-lmstudio.sh|app:LM Studio.app
install-llamacpp.sh|cmd:llama-cli
install-sushi.sh|cmd:sushi
install-dwarfstar.sh|fn:check_dwarfstar
install-vscode.sh|app:Visual Studio Code.app
install-cursor.sh|app:Cursor.app
install-intellij.sh|app:IntelliJ IDEA.app
install-micro.sh|cmd:micro
install-fresh.sh|cmd:fresh
install-croft.sh|cmd:croft
install-language-servers.sh|fn:check_language_servers
install-claude-code.sh|cmd:claude
install-opencode.sh|cmd:opencode
install-little-coder.sh|npm:little-coder
install-pi.sh|npm:@earendil-works/pi-coding-agent
install-oh-my-pi.sh|cmd:omp
install-docker-desktop.sh|app:Docker.app
install-rancher-desktop.sh|app:Rancher Desktop.app
install-orbstack.sh|app:OrbStack.app
install-lima.sh|cmd:limactl
install-utm.sh|app:UTM.app
install-obsidian.sh|app:Obsidian.app
install-chrome.sh|app:Google Chrome.app
install-1password.sh|app:1Password.app
install-gmail.sh|app:Gmail.app
install-google-calendar.sh|app:Google Calendar.app
install-google-contacts.sh|app:Google Contacts.app
install-slack.sh|app:Slack.app
install-discord.sh|app:Discord.app
install-zoom.sh|app:zoom.us.app
install-signal.sh|app:Signal.app
install-tailscale.sh|app:Tailscale.app
install-freerdp.sh|brew:freerdp
install-nas-tools.sh|cmd:smbclient
install-postgres.sh|fn:check_postgres
install-syncthing.sh|app:Syncthing.app
install-unison.sh|cmd:unison:-version
install-vlc.sh|app:VLC.app
install-handbrake.sh|app:HandBrake.app
install-modern-cli.sh|fn:check_modern_cli
install-nerd-fonts.sh|fn:check_nerd_fonts
install-starship.sh|cmd:starship
install-btop.sh|cmd:btop
install-ghostty.sh|app:Ghostty.app
install-iterm2.sh|app:iTerm.app
install-zsh-plugins.sh|fn:check_zsh_plugins'

check_script() {
    local script="$1" spec="$2" kind target args path
    kind="${spec%%:*}"
    target="${spec#*:}"
    case "$kind" in
        app)
            if path="$(app_path "$target")"; then ok "$script" "$(app_version "$path")"; else missing "$script"; fi
            ;;
        cmd)
            args="--version"
            case "$target" in *:*) args="${target#*:}"; target="${target%%:*}" ;; esac
            if command -v "$target" >/dev/null 2>&1; then
                # shellcheck disable=SC2086  # args is a single flag or word
                ok "$script" "$(version_of "$target" $args)"
            else
                missing "$script"
            fi
            ;;
        brew)
            if brew list --formula "$target" >/dev/null 2>&1; then ok "$script" "$(brew list --versions "$target")"; else missing "$script"; fi
            ;;
        npm)
            local v=""
            command -v npm >/dev/null 2>&1 && v="$(npm ls -g --depth=0 "$target" 2>/dev/null | grep -o -- "$target@[^ ]*" | head -1 || true)"
            if [ -n "$v" ]; then ok "$script" "$v"; else missing "$script"; fi
            ;;
        fn) "$target" "$script" ;;
    esac
}

# --- Report, grouped like the menu ---------------------------------------------
current=""
while IFS='|' read -r category _ticked command _label; do
    script="${command#./}"
    case "$script" in install-*.sh | update-versions.sh) ;; *) continue ;; esac
    if [ "$category" != "$current" ]; then
        echo
        echo "$category"
        current="$category"
    fi
    spec="$(printf '%s\n' "$CHECKS" | sed -n "s/^${script//./\\.}|//p")"
    if [ -n "$spec" ]; then check_script "$script" "$spec"; else warn "$script" "no doctor check defined"; fi
done < <(./install-master.sh --list)

# --- Health checks ------------------------------------------------------------
echo
echo "Health"
if command -v brew >/dev/null 2>&1; then
    if grep -qs 'brew shellenv' "$HOME/.zprofile"; then ok "Homebrew" "$(version_of brew --version), on PATH via ~/.zprofile"
    else broken "Homebrew" "not set up in ~/.zprofile, so new terminals won't find brew (run bootstrap.sh)"; fi
else
    broken "Homebrew" "not installed (run bootstrap.sh)"
fi

if grep -qsF '# >>> mac-install: load ~/.zshrc.d >>>' "$HOME/.zshrc"; then
    ok "zshrc.d loader" "$(find "$HOME/.zshrc.d" -name '*.zsh' 2>/dev/null | wc -l | tr -d ' ') snippets"
else
    missing "zshrc.d loader" "not set up yet (any install script adds it)"
fi

dupes="$(printf '%s\n' "$PATH" | tr ':' '\n' | sort | uniq -d | tr '\n' ' ')"
if [ -z "$dupes" ]; then ok "PATH" "no duplicates"; else warn "PATH" "duplicate entries: $dupes"; fi

if command -v fresh >/dev/null 2>&1; then
    if grep -qs '"auto_start": true' "$HOME/.config/fresh/config.json"; then ok "Fresh language servers" "auto-start configured"
    else warn "Fresh language servers" "auto-start not configured (run install-language-servers.sh)"; fi
fi

if [ -f "$HOME/.mac-install/restore-macos-defaults.sh" ]; then
    ok "macOS settings" "$(grep -c '^# setting:' "$HOME/.mac-install/restore-macos-defaults.sh") changed (undo: ~/.mac-install/restore-macos-defaults.sh)"
fi

if [ "$RUN_BREW_DOCTOR" = 1 ] && command -v brew >/dev/null 2>&1; then
    if out="$(brew doctor 2>&1)"; then
        ok "brew doctor" "no problems"
    else
        n="$(printf '%s\n' "$out" | grep -cE '^(Warning|Error):' || true)"
        if [ "$n" -gt 0 ]; then
            first="$(printf '%s\n' "$out" | grep -m1 -E '^(Warning|Error):' | cut -c1-70)"
            warn "brew doctor" "$n issue(s), first: $first — run 'brew doctor' for details"
        else
            first="$(printf '%s\n' "$out" | grep -m1 -v '^[[:space:]]*$' | cut -c1-70)"
            warn "brew doctor" "\"$first\" — run 'brew doctor' for details"
        fi
    fi
fi

echo
if [ "$BROKEN" = 1 ]; then
    echo "Some things are broken (✗) — re-running the script named on the left usually fixes it."
    exit 1
fi
echo "Nothing broken."
