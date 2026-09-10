#!/usr/bin/env bash
# DESTRUCTIVE: drops all Postgres data and restarts fresh.
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose down -v
docker compose up -d
echo "Database reset complete."