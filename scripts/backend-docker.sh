#!/usr/bin/env bash
# Run npm/Node commands for backend/ inside Docker so node_modules stays off the
# host filesystem (anonymous volume for /app/node_modules). Requires Docker.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/backend"
IMAGE="${NODE_IMAGE:-node:20-bookworm-slim}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found. Install Docker Desktop (or Podman with docker alias)." >&2
  exit 1
fi

cmd="${*:-npm ci && npm run typecheck && npm test}"

docker run --rm \
  -v "$BACKEND:/app" \
  -v /app/node_modules \
  -w /app \
  "$IMAGE" \
  bash -lc "$cmd"
