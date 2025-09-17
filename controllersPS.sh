#!/usr/bin/env bash
#set -euo pipefail
#set -x

source ./env.sh
source ./env-ssl.sh

export logLine="cb-ci"
docker compose -f docker-compose.yaml ps |grep ha-client-controller*

