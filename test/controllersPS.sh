#!/usr/bin/env bash
#set -euo pipefail
#set -x

# scripts rely on repo-root relative paths (.env, docker-compose.yaml)
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

source .env
# comment/disable when not using ssl
source .env-ssl

export logLine="cb-ci"
docker compose -f docker-compose.yaml ps |grep ha-client-controller*

