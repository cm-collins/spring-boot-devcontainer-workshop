#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ "${1:-}" != "--yes" ]; then
    echo "This removes the generated Spring Boot application files."
    echo
    echo "Files/directories removed:"
    echo "- pom.xml"
    echo "- Dockerfile"
    echo "- .dockerignore"
    echo "- mvnw"
    echo "- mvnw.cmd"
    echo "- .mvn/"
    echo "- src/"
    echo "- target/"
    echo "- HELP.md"
    echo
    echo "Run with --yes to continue:"
    echo "bash scripts/reset-generated-spring-boot-project.sh --yes"
    exit 1
fi

cd "$REPO_ROOT"

for path in pom.xml Dockerfile .dockerignore mvnw mvnw.cmd .mvn src target HELP.md; do
    if [ -e "$path" ]; then
        echo "Removing $path"
        rm -rf "$path"
    fi
done

echo
echo "Generated Spring Boot application removed."
echo "Run bash scripts/create-spring-boot-project.sh to generate it again."
