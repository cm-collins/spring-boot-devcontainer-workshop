#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/.devcontainer/compose.yaml"
POSTGRES_DB="${POSTGRES_DB:-spring_boot_dev}"
POSTGRES_USER="${POSTGRES_USER:-spring_boot}"
POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

postgres_status="not running"
if docker compose -f "$COMPOSE_FILE" exec -T postgres \
    pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    postgres_status="ready"
fi

echo
echo "========================================"
echo " Spring Boot Dev Container is ready"
echo "========================================"
echo
printf 'Workspace:        %s\n' "$(pwd)"
printf 'Container:        %s\n' "$(hostname)"
printf 'Java:             %s\n' "$(java --version 2>&1 | head -n 1)"
printf 'Maven:            %s\n' "$(mvn --version | head -n 1)"
printf 'Gradle:           %s\n' "$(gradle --version | grep '^Gradle')"
printf 'Docker:           %s\n' "$(docker --version)"
printf 'PostgreSQL:       %s\n' "$postgres_status"
echo
echo "Database connection"
echo "-------------------"
printf 'Inside container:  jdbc:postgresql://%s:%s/%s\n' "$POSTGRES_HOST" "$POSTGRES_PORT" "$POSTGRES_DB"
printf 'Host machine:      localhost:%s\n' "$POSTGRES_PORT"
printf 'Username:          %s\n' "$POSTGRES_USER"
echo
echo "Useful commands"
echo "---------------"
echo "bash .devcontainer/scripts/verify-environment.sh"
echo "bash .devcontainer/scripts/start-postgres.sh"
echo "bash scripts/create-spring-boot-project.sh"
echo "bash scripts/run-spring-boot-app.sh"
echo "bash scripts/reset-generated-spring-boot-project.sh --yes"
echo "docker compose -f .devcontainer/compose.yaml ps"
echo "docker compose -f .devcontainer/compose.yaml exec postgres psql -U spring_boot -d spring_boot_dev"
echo
echo "Next step"
echo "---------"
echo "Run bash scripts/create-spring-boot-project.sh, then start the app with bash scripts/run-spring-boot-app.sh."
echo
echo "========================================"
