#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source lib/brew.sh

# Update everything the install scripts set up, in one go:
#   brew     Homebrew formulae and apps (casks)
#   rust     Rust toolchains (rustup update)
#   uv       uv-managed Python and CLI tools (pylsp, ...)
#   node     Node to the newest LTS via nvm, carrying global npm packages
#            (the pinned pi / little-coder versions) over
#   sdkman   SDKMAN, Groovy and Gradle to their newest versions; Java's
#            default is left alone (it reports a newer Temurin if there is one)
#   pins     report newer releases of the tools pinned on purpose
#            (little-coder, pi, Oh My Pi) — those you bump by hand
#
#   ./update.sh            all steps
#   ./update.sh rust uv    just those
#
# Steps for tools that aren't installed are skipped. A failed step doesn't
# stop the others; the summary lists it and the exit status is non-zero.
# (Internally, a step returns 78 for "tool not installed".)
# macOS itself isn't updated here (see System Settings → General →
# Software Update, or `softwareupdate -l`).
ALL_STEPS="brew rust uv node sdkman pins"

STEPS="${*:-$ALL_STEPS}"
for step in $STEPS; do
    case " $ALL_STEPS " in
        *" $step "*) ;;
        *) echo "Unknown step: $step (choose from: $ALL_STEPS)" >&2; exit 1 ;;
    esac
done

ensure_brew_on_path
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

step_brew() {
    command -v brew >/dev/null 2>&1 || return 78
    brew update
    brew upgrade
}

step_rust() {
    command -v rustup >/dev/null 2>&1 || return 78
    rustup update
}

step_uv() {
    command -v uv >/dev/null 2>&1 || return 78
    uv tool upgrade --all
    # Newer patch releases of the installed Python versions (uv 0.8+).
    if uv python upgrade --help >/dev/null 2>&1; then
        uv python upgrade
    fi
}

step_node() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] || return 78
    # nvm isn't `set -u` safe.
    set +u
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    local current latest
    current="$(nvm version default)"
    latest="$(nvm version-remote 'lts/*')"
    if [ "$latest" = "$current" ]; then
        # (nvm refuses --reinstall-packages-from the version it's installing.)
        echo "Node $current is already the newest LTS."
    elif [ "$current" = "N/A" ]; then
        nvm install "$latest" --latest-npm
        nvm alias default "$latest"
    else
        # Re-install the global packages from the old default, which keeps
        # the pinned npm tools (pi, little-coder) at their versions.
        nvm install "$latest" --reinstall-packages-from="$current" --latest-npm
        nvm alias default "$latest"
        echo "Node default: $current → $latest"
    fi
    set -u
}

step_sdkman() {
    local sdkman_dir="${SDKMAN_DIR:-$HOME/.sdkman}" bash4
    [ -s "$sdkman_dir/bin/sdkman-init.sh" ] || return 78
    # SDKMAN needs Bash 4+ (install-sdkman.sh installs Homebrew's bash).
    bash4="$(brew --prefix 2>/dev/null)/bin/bash"
    [ -x "$bash4" ] || { echo "SDKMAN needs Homebrew's bash; run install-sdkman.sh." >&2; return 1; }
    # SDKMAN's own functions aren't `set -e` safe (an internal non-zero status
    # aborts mid-install), so check each command's result instead.
    SDKMAN_DIR="$sdkman_dir" "$bash4" -c '
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        # SDKMAN reads the lowercase sdkman_auto_answer, which its config
        # resets while loading, so set it after sourcing.
        sdkman_auto_answer=true
        rc=0
        sdk selfupdate || true
        sdk update || rc=1
        # Groovy and Gradle: upgrade to the newest version (each by name;
        # "up-to-date" exits 0).
        for c in groovy gradle; do
            if [ -e "$SDKMAN_DIR/candidates/$c/current" ]; then sdk upgrade "$c" || rc=1; fi
        done
        # Java is left alone: a bare `sdk upgrade` would switch the default to
        # SDKMAN'"'"'s recommended version (e.g. 27 → 25 LTS). Just say when a
        # newer Temurin than the default exists.
        if [ -e "$SDKMAN_DIR/candidates/java/current" ]; then
            cur="$(basename "$(readlink "$SDKMAN_DIR/candidates/java/current")")"
            latest="$(sdk list java 2>/dev/null | awk "{ for (i = 1; i <= NF; i++) if (\$i ~ /-tem\$/) { print \$i; exit } }")"
            if [ -n "$latest" ] && [ "$latest" != "$cur" ]; then
                echo "Java: your default is $cur; the newest Temurin is $latest."
                echo "      To switch: sdk install java $latest"
            else
                echo "Java: $cur is the newest Temurin."
            fi
        fi
        sdk current
        exit "$rc"' </dev/null   # no terminal input: a stray prompt can't hang the update
}

step_pins() {
    ./update-versions.sh
}

declare -a RESULTS=()
FAILED=0
for step in $STEPS; do
    echo
    echo "==> $step"
    set +e
    ( set -e; "step_$step" )
    rc=$?
    set -e
    case "$rc" in
        0) RESULTS+=("  ✓ $step") ;;
        78) RESULTS+=("  – $step (not installed, skipped)") ;;
        *) RESULTS+=("  ✗ $step (exit $rc)"); FAILED=1 ;;
    esac
done

echo
echo "Summary:"
printf '%s\n' "${RESULTS[@]}"
echo
echo "macOS updates: System Settings → General → Software Update (or: softwareupdate -l)"
exit "$FAILED"
