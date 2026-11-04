#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/chrome-app.sh"

# Google Calendar as a Chrome-installed app (see lib/chrome-app.sh).
install_chrome_app "Google Calendar" "https://calendar.google.com/"
