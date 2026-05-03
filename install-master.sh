#!/usr/bin/env bash
# Interactive menu for selecting which install scripts to run.
# Continues past any sub-script that fails; prints a punch list at the end.
#
# Each sub-script has its own `set -e`, so a failed script aborts itself
# before causing harm — we just record it and move on.

# ITEMS holds entries as "category|path" pairs. Order is preserved for
# both the menu and the install run. Add new scripts here.
ITEMS=(
    "Setup|./update-versions.sh"

    "Git/GitHub|./install-git-config.sh"
    "Git/GitHub|./install-gh.sh"

    "Languages|./install-sdkman.sh"
    "Languages|./install-python.sh"
    "Languages|./install-pyenv.sh"
    "Languages|./install-uv.sh"
    "Languages|./install-go.sh"
    "Languages|./install-nodejs.sh"

    "Local LLMs|./install-ollama.sh"
    "Local LLMs|./install-lmstudio.sh"
    "Local LLMs|./install-llamacpp.sh"

    "Editors / dev apps|./install-vscode.sh"
    "Editors / dev apps|./install-cursor.sh"
    "Editors / dev apps|./install-intellij.sh"
    "Editors / dev apps|./install-micro.sh"
    "Editors / dev apps|./install-fresh.sh"
    "Editors / dev apps|./install-claude-code.sh"
    "Editors / dev apps|./install-opencode.sh"
    "Editors / dev apps|./install-little-coder.sh"
    "Editors / dev apps|./install-pi.sh"
    "Editors / dev apps|./install-docker-desktop.sh"

    "Productivity|./install-obsidian.sh"
    "Productivity|./install-chrome.sh"
    "Productivity|./install-1password.sh"
    "Productivity|./install-gmail.sh"
    "Productivity|./install-google-calendar.sh"
    "Productivity|./install-google-contacts.sh"

    "Comms|./install-slack.sh"
    "Comms|./install-discord.sh"
    "Comms|./install-zoom.sh"
    "Comms|./install-signal.sh"

    "Networking|./install-tailscale.sh"

    "Databases|./install-postgres.sh"

    "Sync / utilities|./install-syncthing.sh"
    "Sync / utilities|./install-vlc.sh"
    "Sync / utilities|./install-handbrake.sh"
    "Sync / utilities|./install-utm.sh"

    "Terminal experience|./install-modern-cli.sh"
    "Terminal experience|./install-nerd-fonts.sh"
    "Terminal experience|./install-starship.sh"
    "Terminal experience|./install-btop.sh"
)

# Build parallel arrays from ITEMS (kept bash 3.2 compatible — macOS default).
PATHS=()
CATS=()
SEL=()
CAT_ORDER=()

for entry in "${ITEMS[@]}"; do
    cat="${entry%%|*}"
    path="${entry#*|}"
    PATHS+=("$path")
    CATS+=("$cat")
    SEL+=(1)  # default: everything selected

    # Track unique categories in first-seen order
    seen=0
    for c in "${CAT_ORDER[@]}"; do
        if [ "$c" = "$cat" ]; then seen=1; break; fi
    done
    [ "$seen" -eq 0 ] && CAT_ORDER+=("$cat")
done

NUM_ITEMS=${#PATHS[@]}

# --- Display helpers ---

# ANSI colors (only emit when stdout is a terminal)
if [ -t 1 ]; then
    C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
    C_GREEN=$'\033[32m'; C_CYAN=$'\033[36m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
    C_RESET=$'\033[0m'
else
    C_BOLD=""; C_DIM=""; C_GREEN=""; C_CYAN=""; C_YELLOW=""; C_RED=""; C_RESET=""
fi

print_banner() {
    printf '%s\n' "$C_CYAN"
    cat <<'EOF'
                            _           _        _ _
  _ __ ___   __ _  ___     (_)_ __  ___| |_ __ _| | |
 | '_ ` _ \ / _` |/ __|____| | '_ \/ __| __/ _` | | |
 | | | | | | (_| | (_|_____| | | | \__ \ || (_| | | |
 |_| |_| |_|\__,_|\___|    |_|_| |_|___/\__\__,_|_|_|
EOF
    printf '%s\n' "$C_RESET"
    printf '%s  Welcome — let'\''s set up your Mac.%s\n' "$C_BOLD" "$C_RESET"
    printf '%s  https://github.com/hofftodd/mac-install%s\n' "$C_DIM" "$C_RESET"
    printf '%s  Toggle items below; everything is selected by default.%s\n\n' "$C_DIM" "$C_RESET"
}

# Print a 2-letter shorthand for a category (e.g. "Editors / dev apps" -> "ED").
cat_short() {
    local name="$1"
    local first second
    first="$(printf '%s' "$name" | tr -cd '[:alnum:]' | cut -c1 | tr 'a-z' 'A-Z')"
    second="$(printf '%s' "$name" | tr ' ' '\n' | sed -n '2p' | tr -cd '[:alnum:]' | cut -c1 | tr 'a-z' 'A-Z')"
    if [ -z "$second" ]; then
        printf '%s' "$(printf '%s' "$name" | tr -cd '[:alnum:]' | cut -c1-2 | tr 'a-z' 'A-Z')"
    else
        printf '%s%s' "$first" "$second"
    fi
}

print_menu() {
    local i=0 cat path mark sel_count=0 total=$NUM_ITEMS
    for ((i = 0; i < NUM_ITEMS; i++)); do
        [ "${SEL[$i]}" = "1" ] && sel_count=$((sel_count + 1))
    done

    echo "${C_BOLD}Selected: ${sel_count}/${total}${C_RESET}"
    echo

    local current_cat=""
    for ((i = 0; i < NUM_ITEMS; i++)); do
        cat="${CATS[$i]}"
        path="${PATHS[$i]}"
        if [ "$cat" != "$current_cat" ]; then
            current_cat="$cat"
            local short cat_total=0 cat_sel=0 j
            short="$(cat_short "$cat")"
            for ((j = 0; j < NUM_ITEMS; j++)); do
                if [ "${CATS[$j]}" = "$cat" ]; then
                    cat_total=$((cat_total + 1))
                    [ "${SEL[$j]}" = "1" ] && cat_sel=$((cat_sel + 1))
                fi
            done
            echo
            printf '%s━━ %s %s [%s] (%d/%d)%s\n' \
                "$C_CYAN" "$cat" "$C_DIM" "$short" "$cat_sel" "$cat_total" "$C_RESET"
        fi
        if [ "${SEL[$i]}" = "1" ]; then
            mark="${C_GREEN}[x]${C_RESET}"
        else
            mark="${C_DIM}[ ]${C_RESET}"
        fi
        printf '  %s %3d. %s\n' "$mark" "$((i + 1))" "$(basename "$path")"
    done
    echo
}

print_help() {
    cat <<EOF
${C_BOLD}Commands${C_RESET}
  ${C_CYAN}<n> [n ...]${C_RESET}    toggle items by number (e.g. "3 7 12")
  ${C_CYAN}<n>-<m>${C_RESET}        toggle a range (e.g. "5-9")
  ${C_CYAN}all${C_RESET} / ${C_CYAN}none${C_RESET}    select / deselect everything
  ${C_CYAN}+<CAT>${C_RESET}         select all in a category (e.g. "+ED" or "+Editors")
  ${C_CYAN}-<CAT>${C_RESET}         deselect all in a category
  ${C_CYAN}cats${C_RESET}           list categories with their shortcuts
  ${C_CYAN}list${C_RESET}           redraw the menu
  ${C_CYAN}help${C_RESET}           show this help
  ${C_CYAN}go${C_RESET} / ${C_CYAN}run${C_RESET}      run the selected scripts
  ${C_CYAN}q${C_RESET} / ${C_CYAN}quit${C_RESET}     quit without running
EOF
}

print_categories() {
    echo "${C_BOLD}Categories${C_RESET}"
    local c short
    for c in "${CAT_ORDER[@]}"; do
        short="$(cat_short "$c")"
        printf '  %s%-3s%s  %s\n' "$C_CYAN" "$short" "$C_RESET" "$c"
    done
}

# Set selection for items in a matching category. matcher = shorthand or
# case-insensitive substring of the category name. value = 0 or 1.
set_category() {
    local matcher="$1" value="$2"
    local matched=0 i cat short
    local lc_matcher; lc_matcher="$(printf '%s' "$matcher" | tr 'A-Z' 'a-z')"
    for c in "${CAT_ORDER[@]}"; do
        short="$(cat_short "$c")"
        local lc_cat lc_short
        lc_cat="$(printf '%s' "$c" | tr 'A-Z' 'a-z')"
        lc_short="$(printf '%s' "$short" | tr 'A-Z' 'a-z')"
        if [ "$lc_short" = "$lc_matcher" ] || [[ "$lc_cat" == *"$lc_matcher"* ]]; then
            for ((i = 0; i < NUM_ITEMS; i++)); do
                [ "${CATS[$i]}" = "$c" ] && SEL[$i]="$value"
            done
            matched=1
        fi
    done
    if [ "$matched" -eq 0 ]; then
        echo "${C_YELLOW}No category matches '$matcher'. Try 'cats' to list them.${C_RESET}"
    fi
}

toggle_index() {
    local n="$1"
    if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt "$NUM_ITEMS" ]; then
        echo "${C_YELLOW}Out of range: $n${C_RESET}"
        return
    fi
    local idx=$((n - 1))
    if [ "${SEL[$idx]}" = "1" ]; then
        SEL[$idx]=0
    else
        SEL[$idx]=1
    fi
}

# --- Menu loop ---

print_banner
print_menu
print_help
echo

while true; do
    printf "${C_BOLD}> ${C_RESET}"
    if ! IFS= read -r line; then
        echo
        echo "${C_DIM}EOF — quitting.${C_RESET}"
        exit 0
    fi
    # Strip leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    case "$line" in
        ""|list)
            print_menu
            ;;
        help|"?")
            print_help
            ;;
        cats|categories)
            print_categories
            ;;
        all)
            for ((i = 0; i < NUM_ITEMS; i++)); do SEL[$i]=1; done
            print_menu
            ;;
        none)
            for ((i = 0; i < NUM_ITEMS; i++)); do SEL[$i]=0; done
            print_menu
            ;;
        go|run|"")
            break
            ;;
        q|quit|exit)
            echo "${C_DIM}Quit without running.${C_RESET}"
            exit 0
            ;;
        +*)
            set_category "${line#+}" 1
            print_menu
            ;;
        -*)
            set_category "${line#-}" 0
            print_menu
            ;;
        *)
            # Tokenize on whitespace and commas
            tokens=$(echo "$line" | tr ',' ' ')
            for tok in $tokens; do
                if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                    a="${BASH_REMATCH[1]}"; b="${BASH_REMATCH[2]}"
                    if [ "$a" -gt "$b" ]; then tmp="$a"; a="$b"; b="$tmp"; fi
                    for ((n = a; n <= b; n++)); do toggle_index "$n"; done
                elif [[ "$tok" =~ ^[0-9]+$ ]]; then
                    toggle_index "$tok"
                else
                    echo "${C_YELLOW}Unrecognized: '$tok'. Type 'help'.${C_RESET}"
                fi
            done
            print_menu
            ;;
    esac

    if [ "$line" = "go" ] || [ "$line" = "run" ]; then break; fi
done

# --- Build the run list from selections ---

SCRIPTS=()
for ((i = 0; i < NUM_ITEMS; i++)); do
    [ "${SEL[$i]}" = "1" ] && SCRIPTS+=("${PATHS[$i]}")
done

if [ "${#SCRIPTS[@]}" -eq 0 ]; then
    echo "${C_YELLOW}Nothing selected. Exiting.${C_RESET}"
    exit 0
fi

# --- Run loop (preserved from original, with selected list) ---

SUCCEEDED=()
FAILED=()
SKIPPED=()
LOG_DIR="$(mktemp -d -t mac-install)"

echo
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
