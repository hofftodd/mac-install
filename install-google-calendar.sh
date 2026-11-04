#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/chrome-app.sh"

# Google Calendar as a Chrome "app-mode" launcher in ~/Applications (see lib/chrome-app.sh).
install_chrome_app "Google Calendar" "https://calendar.google.com/" \
    "https://www.gstatic.com/images/branding/product/2x/calendar_2020q4_512dp.png"
