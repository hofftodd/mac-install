#!/usr/bin/env bash
# Runs a representative set of install scripts for real, twice (the second run
# checks they're safe to re-run), then opens a zsh and checks the tools and
# shell setup work there.
#
# ONLY run this on a throwaway Mac (the GitHub Actions runner).
# Scripts run under /bin/bash (3.2), the version a new Mac has.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [ "$(uname -s)" != Darwin ] || [ "${CI:-}" != true ]; then
    echo "Refusing to run: this installs software and edits ~/.zshrc. Only for macOS CI runners (CI=true)." >&2
    exit 1
fi

BASH32=/bin/bash
export GIT_USER_NAME="${GIT_USER_NAME:-mac-install CI}"
export GIT_USER_EMAIL="${GIT_USER_EMAIL:-ci@example.com}"

# Kept to scripts that exercise the shared helpers and the bugs fixed so far,
# while finishing in reasonable time. Order follows the menu.
SCRIPTS=(
    update-versions.sh
    install-git-config.sh
    install-uv.sh
    install-go.sh
    install-rust.sh
    install-nodejs.sh
    install-little-coder.sh
    install-pi.sh
    install-oh-my-pi.sh
    install-fresh.sh
    install-language-servers.sh
    install-bun.sh
    install-sdkman.sh
    install-postgres.sh
    install-iterm2.sh
    install-chrome.sh
    install-gmail.sh
    install-google-calendar.sh
    install-google-contacts.sh
    install-modern-cli.sh
    install-starship.sh
    install-zsh-plugins.sh
)

failures=0
pass() { echo "  ✓ $*"; }
fail() {
    echo "  ✗ $*"
    failures=$((failures + 1))
}

for pass_no in 1 2; do
    for script in "${SCRIPTS[@]}"; do
        echo "::group::run $pass_no: $script"
        start=$SECONDS
        if $BASH32 "./$script" < /dev/null; then
            rc=0
        else
            rc=$?
        fi
        echo "::endgroup::"
        if [ "$rc" = 0 ]; then
            pass "run $pass_no: $script ($((SECONDS - start))s)"
        else
            fail "run $pass_no: $script exited $rc"
        fi
    done
done

echo "== Shell setup in a new zsh"
ls -la "$HOME/.zshrc.d"
# Run each check in an interactive zsh, as a new terminal would.
zcheck() {
    local label="$1" cmd="$2" out
    if out="$(zsh -i -c "$cmd" 2>&1)"; then
        pass "$label${out:+: $(printf '%s' "$out" | tail -1)}"
    else
        fail "$label failed:"$'\n'"$out"
    fi
}
for tool in uv python3 cargo rustc rust-analyzer go node little-coder pi omp bun java gradle psql starship rg eza delta micro; do
    zcheck "$tool on PATH" "command -v $tool"
done
zcheck "python3 is uv's"        '[[ "$(command -v python3)" == "$HOME/.local/bin/python3" ]] && python3 --version'
# /usr/bin/java is Apple's placeholder that only offers to install Java.
zcheck "java is SDKMAN's and runs" '[[ "$(command -v java)" == "$HOME/.sdkman/"* ]] && java -version 2>&1 | head -1'
zcheck "rustc runs"             'rustc --version'
zcheck "omp is the pinned release" 'omp --version'
zcheck "little-coder is the pinned release" 'npm ls -g --depth=0 little-coder | grep little-coder@'
zcheck "pi is the pinned release" 'npm ls -g --depth=0 @earendil-works/pi-coding-agent | grep pi-coding-agent@'
zcheck "fresh runs"             'fresh --version'
for server in gopls pylsp typescript-language-server vscode-json-language-server bash-language-server yaml-language-server taplo marksman jdtls sqls clangd; do
    zcheck "$server (language server) on PATH" "command -v $server"
done
zcheck "marksman runs"          'marksman --version'
zcheck "pylsp runs"             'pylsp --version'
zcheck "Fresh auto-starts installed servers" 'python3 -c "import json,os; l=json.load(open(os.path.expanduser(\"~/.config/fresh/config.json\")))[\"lsp\"]; assert all(l[k][\"auto_start\"] for k in (\"rust\",\"go\",\"python\",\"typescript\",\"markdown\",\"c\")); print(len(l), \"languages\")"'
zcheck "psql connects"          'psql -d postgres -tAc "select 1"'
zcheck "tab completion is on"   '(( $+functions[compdef] ))'
zcheck "uv completion loaded"   '[[ -n "${_comps[uv]:-}" ]]'
zcheck "PATH has no duplicates" '[[ ${#path} -eq $(print -l $path | sort -u | wc -l) ]]'
zcheck "fzf Ctrl-R history search" '(( $+widgets[fzf-history-widget] ))'
zcheck "zsh-autosuggestions loaded" '(( $+functions[_zsh_autosuggest_start] ))'
zcheck "zsh-syntax-highlighting loaded" '(( $+functions[_zsh_highlight] ))'
zcheck "direnv hook installed" '(( ${precmd_functions[(I)_direnv_hook]} ))'
zcheck "git pager is delta"     '[[ "$(git config --global core.pager)" == delta ]]'

echo "== Chrome app launchers"
for app in "Gmail" "Google Calendar" "Google Contacts"; do
    bundle="$HOME/Applications/$app.app"
    exe="$bundle/Contents/MacOS/$(printf '%s' "$app" | tr -d ' ')"
    if ! plutil -lint "$bundle/Contents/Info.plist" >/dev/null; then
        fail "$app.app: Info.plist missing or invalid"
    elif [ ! -x "$exe" ]; then
        fail "$app.app: launcher $exe missing or not executable"
    elif ! grep -qF -- '--app="https://' "$exe"; then
        fail "$app.app: launcher doesn't open Chrome in app mode:"$'\n'"$(cat "$exe")"
    else
        pass "$app.app: valid Info.plist, launcher opens Chrome in app mode"
    fi
done

echo "== update.sh (all steps except brew, which would upgrade the runner's own packages)"
if ./update.sh rust uv node sdkman pins; then pass "update.sh rust uv node sdkman pins"; else fail "update.sh exited non-zero"; fi

echo "== Repo left clean (update-versions must not edit tracked files)"
if [ -z "$(git status --porcelain)" ]; then pass "no changes in the checkout"; else fail "checkout modified:"$'\n'"$(git status --porcelain)"; fi

echo
if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed."
    exit 1
fi
echo "✓ all install checks passed"
