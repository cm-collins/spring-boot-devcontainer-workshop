#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " Spring Boot Dev Container"
echo " Post-start"
echo "========================================"

echo
echo "Container:"
hostname

echo
echo "Java:"
java --version

echo
echo "Workspace:"
pwd

echo
echo "========================================"
echo " Container is ready"
echo "========================================"