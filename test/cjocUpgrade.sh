#!/usr/bin/env bash
#set -euo pipefail
set -x

# scripts rely on repo-root relative paths (.env, docker-compose.yaml)
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

source .env
# comment/disable when not using ssl
source .env-ssl

export DOCKER_IMAGE_CLOUDBEES_CJOC_TAG=2.516.2.29000-jdk21
export DOCKER_IMAGE_OC=cloudbees/cloudbees-core-oc:${DOCKER_IMAGE_CLOUDBEES_CJOC_TAG}
export logLine="cb-ci"
export SERVICE_OC=operations-center

# Pull and recreate only this service
docker compose -f docker-compose.yaml pull "$SERVICE_OC"
docker compose -f docker-compose.yaml up -d --no-deps "$SERVICE_OC"

# Retry until HTTP 200 from inside the operations-center container
until status=$(
     curl -k -s -o /dev/null -w "%{http_code}" \
      --connect-timeout 2 --max-time 5 \
      "https://oc.ha/whoAmI/api/json?tree=authenticated"
  ) && [[ "$status" -eq 200 ]]; do
    echo "$SERVICE_OC returned HTTP $status — retrying in 5s..."
    sleep 5
done

echo "$SERVICE_OC is healthy (HTTP 200)"
docker compose -f docker-compose.yaml ps "$SERVICE_OC"

