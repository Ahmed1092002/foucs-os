#!/usr/bin/env bash
# Start local dev stack (Postgres + pgAdmin)
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose up -d
echo "Postgres: localhost:5434 (user=focus, db=focus_os)"
echo "pgAdmin:  http://localhost:5050  (admin@local.dev / admin)"