#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -f "$REPO_ROOT/pom.xml" ] || [ ! -x "$REPO_ROOT/mvnw" ]; then
    echo "ERROR: No generated Spring Boot project was found."
    echo "Run: bash scripts/create-spring-boot-project.sh"
    exit 1
fi

if [ -f "$REPO_ROOT/.devcontainer/scripts/start-postgres.sh" ]; then
    bash "$REPO_ROOT/.devcontainer/scripts/start-postgres.sh"
fi

echo
echo "Starting Spring Boot..."
echo "Press Ctrl+C to stop the application."
echo

cd "$REPO_ROOT"
exec ./mvnw spring-boot:run
