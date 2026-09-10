#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

python3 -m venv .venv
.venv/bin/python -m pip install -r simple_agent/azure/src/requirements.txt
.venv/bin/python -m pip check

terraform version
tflint --version
az version
gh --version
docker --version
.venv/bin/python --version

printf '%s\n' 'Setup complete. Authenticate with Azure CLI before planning or deploying.'