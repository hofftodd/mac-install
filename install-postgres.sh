#!/usr/bin/env bash
set -euo pipefail

# Install PostgreSQL + pgcli (a nicer psql) via Homebrew.
# postgresql@16 is the current stable LTS-ish on brew; bump as needed.
PG_FORMULA="${PG_FORMULA:-postgresql@16}"

brew install "$PG_FORMULA" pgcli

# Start (and enable at login) as a per-user brew service.
brew services start "$PG_FORMULA"

# Make sure the brew-installed psql is on PATH for this shell.
PG_PREFIX="$(brew --prefix "$PG_FORMULA")"
export PATH="${PG_PREFIX}/bin:$PATH"

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
echo "Connect with: psql   (or: pgcli)"
echo "Manage with: brew services {start,stop,restart} ${PG_FORMULA}"
