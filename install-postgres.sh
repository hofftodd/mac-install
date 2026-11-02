#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/brew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/versions.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/zshrc.sh"

# PostgreSQL + pgcli (a nicer psql) via Homebrew, running as a per-user
# brew service.
#
# Which version:
#   PG_FORMULA=postgresql@17 ./install-postgres.sh   — exactly this one.
#   Otherwise, if a postgresql@N is already installed, keep using it: each
#   major version has its own data directory and they all want port 5432, so
#   moving to a newer major is a deliberate upgrade (steps printed below).
#   Otherwise install the newest major: PG_LATEST_FORMULA from
#   update-versions.sh, or the built-in default.
ensure_brew_on_path
USER="${USER:-$(id -un)}"

if [ -n "${PG_FORMULA:-}" ]; then
    : # explicit choice
else
    LATEST="${PG_LATEST_FORMULA:-postgresql@18}"
    # Newest postgresql@N already installed, if any.
    EXISTING="$(brew list --formula 2>/dev/null | grep -E '^postgresql@[0-9]+$' | sort -t@ -k2 -n | tail -1 || true)"
    if [ -n "$EXISTING" ]; then
        PG_FORMULA="$EXISTING"
        if [ "$EXISTING" != "$LATEST" ]; then
            echo "Keeping your installed $EXISTING ($LATEST is the newest)."
            echo "To upgrade, back up your databases, then (see https://www.postgresql.org/docs/current/upgrading.html):"
            echo "  pg_dumpall > ~/pg-backup.sql"
            echo "  brew services stop $EXISTING"
            echo "  PG_FORMULA=$LATEST ./install-postgres.sh"
            echo "  psql -d postgres -f ~/pg-backup.sql"
            echo
        fi
    else
        PG_FORMULA="$LATEST"
    fi
fi

brew install "$PG_FORMULA" pgcli

# Homebrew's postgresql@N formulae are keg-only (not linked into brew's bin),
# so put this version's psql, pg_dump, createdb... on PATH for new shells.
PG_PREFIX="$(brew --prefix "$PG_FORMULA")"
install_zshrc_snippet 20-postgres <<EOF
# $PG_FORMULA client tools (psql, pg_dump, createdb, ...). Re-run install-postgres.sh after changing versions.
export PATH="$PG_PREFIX/bin:\$PATH"
EOF
export PATH="$PG_PREFIX/bin:$PATH"

# Start (and enable at login) as a per-user brew service.
brew services start "$PG_FORMULA"

# Wait briefly for the server to come up before issuing role/db commands.
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if psql -d postgres -tAc 'SELECT 1' >/dev/null 2>&1; then break; fi
    sleep 1
done

# Brew creates a superuser role matching $USER and a `postgres` db, but no
# matching db; create one so `psql` with no args "just works".
if ! psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${USER}'" 2>/dev/null | grep -q 1; then
    createdb "$USER" 2>/dev/null || true
fi

echo "PostgreSQL running ($PG_FORMULA): $(psql -d postgres -tAc 'SELECT version()' 2>/dev/null || echo '(not ready yet)')"
echo "Connect with: psql   (or: pgcli)   — in a new shell, or after: source ~/.zshrc"
echo "Manage with: brew services {start,stop,restart} ${PG_FORMULA}"
