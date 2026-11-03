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
#   sdkman   SDKMAN, then Java, Groovy and Gradle to their newest versions
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
    SDKMAN_DIR="$sdkman_dir" "$bash4" -c '
        set -e
        export SDKMAN_AUTO_ANSWER=true
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        sdk selfupdate || true
        sdk update
        # `sdk upgrade` exits 1 when there is nothing to upgrade.
        if ! out="$(sdk upgrade 2>&1)"; then
            printf "%s\n" "$out"
            case "$out" in *"No new candidates found"*) ;; *) exit 1 ;; esac
        else
            printf "%s\n" "$out"
        fi
        sdk current'
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
