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
ENV_FILE=.env.${CLIENT}
if [ ! -f $ENV_FILE ]; then
    echo "❌ Environment file $ENV_FILE not found!"
    exit 1
fi

echo "📁 Loading environment from: $ENV_FILE"
set -a
source $ENV_FILE
set +a

echo "🚀 Running '$COMMAND' for client '$CLIENT' in mode '$MODE'..."
echo "Using N8N_HOST=$N8N_HOST"

if [ "$COMMAND" = "up" ]; then
  docker compose \
    --env-file $ENV_FILE \
    -f docker-compose.base.yml \
    -f docker-compose.${MODE}.override.yml \
    up -d
else
  docker compose \
    --env-file $ENV_FILE \
    -f docker-compose.base.yml \
    -f docker-compose.${MODE}.override.yml \
    $COMMAND
fi

echo "✅ Done!"
