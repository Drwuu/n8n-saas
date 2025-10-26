#!/usr/bin/env bash
# Usage: ./up-client.sh <client> <mode: dev|prod> [command: up|down]

CLIENT=$1
MODE=${2:-dev}        # default = dev
COMMAND=${3:-up}      # default = up

if [ -z "$CLIENT" ]; then
  echo "❌ Please provide a client name (e.g. ./up-client.sh client1 dev up)"
  exit 1
fi

# Merge env files
set -a
source ${CLIENT}.env
set +a

echo "🚀 Running '$COMMAND' for client '$CLIENT' in mode '$MODE'..."
echo "Using N8N_HOST=$N8N_HOST"

if [ "$COMMAND" = "up" ]; then
  docker compose \
    -f docker-compose.base.yml \
    -f docker-compose.${MODE}.override.yml \
    up -d
else
  docker compose \
    -f docker-compose.base.yml \
    -f docker-compose.${MODE}.override.yml \
    $COMMAND
fi

echo "✅ Done!"
