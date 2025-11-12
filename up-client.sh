#!/usr/bin/env bash
# N8N Multi-Client Deployment Script

show_help() {
  cat << EOF
N8N Multi-Client Deployment Script

Usage: ./up-client.sh <client> [mode] [command]

Arguments:
  client          Client name (required) - must have corresponding .env.<client> file
  mode            Deployment mode (optional, default: dev)
                  - dev: Local development with HTTP
                  - prod: Production with HTTPS via Traefik
  command         Docker Compose command (optional, default: up)
                  - up: Start services in detached mode
                  - down: Stop and remove services
                  - logs: View service logs
                  - ps: List running services
                  - restart: Restart services

Examples:
  ./up-client.sh playsmart                    # Start playsmart in dev mode
  ./up-client.sh playsmart prod               # Start playsmart in production
  ./up-client.sh playsmart prod down          # Stop playsmart production
  ./up-client.sh playsmart dev logs           # View playsmart dev logs
  ./up-client.sh playsmart prod restart       # Restart playsmart production

Requirements:
  - .env.<client> file must exist
  - Docker networks (proxy, monitoring) must be created for prod mode
  - Traefik must be running for prod mode HTTPS

EOF
}

# Show help if requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_help
  exit 0
fi

CLIENT=$1
MODE=${2:-dev}        # default = dev
COMMAND=${3:-up}      # default = up

if [ -z "$CLIENT" ]; then
  echo "❌ Please provide a client name"
  echo ""
  show_help
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

# Check/create required Docker networks
echo "🔍 Checking Docker networks..."

# External networks (shared across clients)
for network in proxy monitoring; do
  if ! docker network ls | grep -q " $network "; then
    echo "📡 Creating external network: $network"
    docker network create $network
  fi
done

# Internal network (per-client)
INTERNAL_NETWORK="internal_${CLIENT}"
if ! docker network ls | grep -q " $INTERNAL_NETWORK "; then
  echo "📡 Creating internal network: $INTERNAL_NETWORK"
  docker network create $INTERNAL_NETWORK
fi

# Check/create Docker volumes if command is 'up'
if [ "$COMMAND" = "up" ]; then
  echo "🔍 Checking Docker volumes..."
  
  POSTGRES_VOLUME="postgres_data_${CLIENT}"
  N8N_VOLUME="n8n_data_${CLIENT}"
  N8N_FILES_VOLUME="n8n_files_${CLIENT}"
  
  for volume in $POSTGRES_VOLUME $N8N_VOLUME $N8N_FILES_VOLUME; do
    if ! docker volume ls | grep -q " $volume "; then
      echo "💾 Creating volume: $volume"
      docker volume create $volume
    fi
  done
fi

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
