#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " Starting local development services"
echo "========================================"

COMPOSE_FILE=".devcontainer/compose.yaml"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: $COMPOSE_FILE was not found."
    exit 1
fi

echo
echo "Starting PostgreSQL..."

docker compose \
    -f "$COMPOSE_FILE" \
    up -d

echo
echo "Waiting for PostgreSQL to become healthy..."

until docker compose \
    -f "$COMPOSE_FILE" \
    exec -T postgres \
    pg_isready \
    -U spring_boot \
    -d spring_boot_dev \
    >/dev/null 2>&1
do
    sleep 2
done

echo
echo "✓ PostgreSQL is ready."

echo
echo "========================================"
echo " Local development services are ready"
echo "========================================"