#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " Dev Container post-create setup"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "Verifying the development environment..."
bash "$SCRIPT_DIR/verify-environment.sh"

echo
echo "Starting local development services..."
bash "$SCRIPT_DIR/start-postgres.sh"

echo
echo "========================================"
echo " Dev Container setup complete"
echo "========================================"
