#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/chrome-app.sh"

# Google Contacts as a Chrome-installed app (see lib/chrome-app.sh).
install_chrome_app "Google Contacts" "https://contacts.google.com/"
