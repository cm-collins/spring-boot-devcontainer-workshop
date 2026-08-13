#!/usr/bin/env bash

set -euo pipefail

echo
echo "========================================"
echo " Spring Boot Dev Container Verification"
echo "========================================"

check_command() {
    local name="$1"
    local command="$2"

    if command -v "$command" >/dev/null 2>&1; then
        echo "✓ $name"
    else
        echo "✗ $name"
        return 1
    fi
}

echo
echo "Development Tools"
echo "------------------"

check_command "Java" "java"
check_command "Maven" "mvn"
check_command "Gradle" "gradle"
check_command "Git" "git"
check_command "GitHub CLI" "gh"
check_command "Azure CLI" "az"
check_command "Python" "python3"
check_command "Docker" "docker"

if docker compose version >/dev/null 2>&1; then
    echo "✓ Docker Compose"
else
    echo "✗ Docker Compose"
    exit 1
fi

echo
echo "Versions"
echo "--------"

echo "Java:"
java --version 2>&1 | head -n 1

echo
echo "Maven:"
mvn --version | head -n 2

echo
echo "Gradle:"
gradle --version | grep '^Gradle'

echo
echo "Git:"
git --version

echo
echo "GitHub CLI:"
gh --version | head -n 1

echo
echo "Azure CLI:"
az version --output tsv --query '"azure-cli"' 2>/dev/null || az version

echo
echo "Python:"
python3 --version

echo
echo "Docker:"
docker --version

echo
echo "Docker Compose:"
docker compose version

echo
echo "========================================"
echo " ✓ Environment verification complete"
echo "========================================"