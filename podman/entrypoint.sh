#!/usr/bin/env bash
set -euo pipefail

# Default values (can be overridden at runtime with -e)
HOST="${FASTAPI_HOST:-0.0.0.0}"
PORT="${FASTAPI_PORT:-8080}"
WORKERS="${UVICORN_WORKERS:-1}"

echo "Starting FastAPI on ${HOST}:${PORT} with ${WORKERS} worker(s)"

exec uvicorn main:app \
  --host "$HOST" \
  --port "$PORT" \
  --workers "$WORKERS" \
  "$@"
