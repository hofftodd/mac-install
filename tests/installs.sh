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
    install-bun.sh
    install-sdkman.sh
    install-postgres.sh
    install-iterm2.sh
    install-chrome.sh
    install-modern-cli.sh
    install-starship.sh
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
for tool in uv python3 cargo rustc rust-analyzer go node bun java gradle psql starship rg eza delta micro; do
    zcheck "$tool on PATH" "command -v $tool"
done
zcheck "python3 is uv's"        '[[ "$(command -v python3)" == "$HOME/.local/bin/python3" ]] && python3 --version'
# /usr/bin/java is Apple's placeholder that only offers to install Java.
zcheck "java is SDKMAN's and runs" '[[ "$(command -v java)" == "$HOME/.sdkman/"* ]] && java -version 2>&1 | head -1'
zcheck "rustc runs"             'rustc --version'
zcheck "psql connects"          'psql -d postgres -tAc "select 1"'
zcheck "tab completion is on"   '(( $+functions[compdef] ))'
zcheck "uv completion loaded"   '[[ -n "${_comps[uv]:-}" ]]'
zcheck "PATH has no duplicates" '[[ ${#path} -eq $(print -l $path | sort -u | wc -l) ]]'
zcheck "git pager is delta"     '[[ "$(git config --global core.pager)" == delta ]]'

echo "== Repo left clean (update-versions must not edit tracked files)"
if [ -z "$(git status --porcelain)" ]; then pass "no changes in the checkout"; else fail "checkout modified:"$'\n'"$(git status --porcelain)"; fi

echo
if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed."
    exit 1
fi
echo "✓ all install checks passed"
