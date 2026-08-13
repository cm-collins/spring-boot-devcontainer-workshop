#!/usr/bin/env bash

set -euo pipefail

echo
echo "========================================"
echo " Development environment verification"
echo "========================================"

check_command() {
    local name="$1"
    local command="$2"

    if command -v "$command" >/dev/null 2>&1; then
        printf '[ok]      %s\n' "$name"
    else
        printf '[missing] %s\n' "$name"
        return 1
    fi
}

echo
echo "Required tools"
echo "--------------"

check_command "Java" "java"
check_command "Java compiler" "javac"
check_command "Maven" "mvn"
check_command "Gradle" "gradle"
check_command "Git" "git"
check_command "GitHub CLI" "gh"
check_command "Azure CLI" "az"
check_command "Python" "python3"
check_command "Docker" "docker"

if docker compose version >/dev/null 2>&1; then
    printf '[ok]      %s\n' "Docker Compose"
else
    printf '[missing] %s\n' "Docker Compose"
    exit 1
fi

echo
echo "Installed versions"
echo "------------------"

printf 'Java:           '
java --version 2>&1 | head -n 1

printf 'Maven:          '
mvn --version | head -n 1

printf 'Gradle:         '
gradle --version | grep '^Gradle'

printf 'Git:            '
git --version

printf 'GitHub CLI:     '
gh --version | head -n 1

printf 'Azure CLI:      '
az version --output tsv --query '"azure-cli"' 2>/dev/null || az version

printf 'Python:         '
python3 --version

printf 'Docker:         '
docker --version

printf 'Docker Compose: '
docker compose version

echo
echo "Environment verification complete."
