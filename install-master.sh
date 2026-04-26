#!/usr/bin/env bash
# Run every install-* script in order, continuing past any that fail.
# Prints a punch list of failures at the end.
#
# Each sub-script has its own `set -e`, so a failed script aborts itself
# before causing harm — we just record it and move on.

SCRIPTS=(
    # Refresh pinned versions before installing
    ./update-versions.sh

    # Git / GitHub
    ./install-git-config.sh
    ./install-gh.sh

    # Languages & runtimes
    ./install-sdkman.sh
    ./install-python.sh
    ./install-pyenv.sh
    ./install-uv.sh
    ./install-go.sh
    ./install-nodejs.sh

    # Local LLMs
    ./install-ollama.sh
    ./install-lmstudio.sh
    ./install-llamacpp.sh

    # Editors / dev apps
    ./install-vscode.sh
    ./install-cursor.sh
    ./install-intellij.sh
    ./install-micro.sh
    ./install-claude-code.sh
    ./install-opencode.sh
    ./install-pi.sh
    ./install-docker-desktop.sh

    # Productivity
    ./install-obsidian.sh
    ./install-chrome.sh
    ./install-1password.sh
    ./install-gmail.sh
    ./install-google-calendar.sh
    ./install-google-contacts.sh

    # Comms
    ./install-slack.sh
    ./install-discord.sh
    ./install-zoom.sh
    ./install-signal.sh

    # Networking
    ./install-tailscale.sh

    # Databases
    ./install-postgres.sh

    # Sync / utilities
    ./install-syncthing.sh
    ./install-vlc.sh
    ./install-handbrake.sh

    # Terminal experience
    ./install-modern-cli.sh
    ./install-nerd-fonts.sh
    ./install-starship.sh
    ./install-btop.sh
)

SUCCEEDED=()
FAILED=()
SKIPPED=()
LOG_DIR="$(mktemp -d -t mac_install)"

echo "Logs: $LOG_DIR"
echo "Running ${#SCRIPTS[@]} scripts..."
echo

for script in "${SCRIPTS[@]}"; do
    name="$(basename "$script")"
    if [ ! -x "$script" ]; then
        printf '  ? %-32s (not executable, skipped)\n' "$name"
        SKIPPED+=("$script")
        continue
    fi
    printf '→ %s\n' "$name"
    log_file="$LOG_DIR/${name}.log"
    "$script" 2>&1 | tee "$log_file"
    rc=${PIPESTATUS[0]}
    if [ "$rc" -eq 0 ]; then
        SUCCEEDED+=("$script")
        printf '  ✓ %s\n' "$name"
    else
        FAILED+=("$script")
        printf '  ✗ %s (exit %d) — see %s\n' "$name" "$rc" "$log_file"
    fi
    echo
done

echo "============================================================"
echo "  Summary"
echo "============================================================"
printf '  Succeeded: %d\n' "${#SUCCEEDED[@]}"
printf '  Failed:    %d\n' "${#FAILED[@]}"
printf '  Skipped:   %d\n' "${#SKIPPED[@]}"
echo

if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "Failed scripts (re-run individually after diagnosing):"
    for s in "${FAILED[@]}"; do
        echo "  - $s   (log: $LOG_DIR/$(basename "$s").log)"
    done
    echo
fi

if [ "${#SKIPPED[@]}" -gt 0 ]; then
    echo "Skipped (not executable):"
    for s in "${SKIPPED[@]}"; do
        echo "  - $s"
    done
    echo
fi

[ "${#FAILED[@]}" -eq 0 ]
