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

remove_path() {
    local path="$1"

    echo "Removing $path"

    if rm -rf "$path" 2>/dev/null; then
        return
    fi

    if command -v sudo >/dev/null 2>&1; then
        echo "Standard removal failed. Retrying with sudo because $path may be owned by another container user."
        sudo rm -rf "$path"
        return
    fi

    echo "ERROR: Could not remove $path."
    echo "It may be owned by another user. Fix ownership, then run this script again:"
    echo "sudo chown -R \"\$(id -u):\$(id -g)\" $path"
    exit 1
}

for path in pom.xml Dockerfile .dockerignore mvnw mvnw.cmd .mvn src target HELP.md; do
    if [ -e "$path" ]; then
        remove_path "$path"
    fi
done

echo
echo "Generated Spring Boot application removed."
echo "Run bash scripts/create-spring-boot-project.sh to generate it again."
