#!/usr/bin/env bash
#set -euo pipefail
#set -x

source .env
# comment/disable when not using ssl
source .env-ssl

export logLine="cb-ci"
docker compose -f docker-compose.yaml ps |grep ha-client-controller*

