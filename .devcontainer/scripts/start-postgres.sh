#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/.devcontainer/compose.yaml"
NETWORK_NAME="spring-dev-network"
POSTGRES_SERVICE="postgres"
POSTGRES_DB="${POSTGRES_DB:-spring_boot_dev}"
POSTGRES_USER="${POSTGRES_USER:-spring_boot}"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: $COMPOSE_FILE was not found."
    exit 1
fi

echo "Starting PostgreSQL with Docker Compose..."
docker compose -f "$COMPOSE_FILE" up -d "$POSTGRES_SERVICE"

container_id="$(hostname)"

if docker inspect "$container_id" >/dev/null 2>&1; then
    if docker inspect "$container_id" \
        --format '{{json .NetworkSettings.Networks}}' \
        | grep -q "\"$NETWORK_NAME\""; then
        echo "Dev Container is already attached to $NETWORK_NAME."
    else
        echo "Attaching Dev Container to $NETWORK_NAME..."
        docker network connect "$NETWORK_NAME" "$container_id"
    fi
else
    echo "Skipping Dev Container network attach; current container was not found by Docker."
fi

echo "Waiting for PostgreSQL to become healthy..."
until docker compose -f "$COMPOSE_FILE" exec -T "$POSTGRES_SERVICE" \
    pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1
do
    sleep 2
done

echo "PostgreSQL is ready."
