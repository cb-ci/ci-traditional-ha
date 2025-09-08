#!/usr/bin/env bash
#set -euo pipefail
set -x

source ./env.sh
source ./env-ssl.sh

export logLine="cb-ci"

for controller in $(docker compose config --services |grep "ha-client*"); do
  echo "Processing $controller"

  if [ -f "$VERSION_TXT_PATH" ]
  then
    rm -v $VERSION_TXT_PATH
  fi
  docker compose -f docker-compose.yaml restart  "$controller"

  # Retry until HTTP 200 from inside the operations-center container
  until status=$(
    docker compose -f docker-compose.yaml exec -T operations-center \
      curl -k -s -o /dev/null -w "%{http_code}" \
      --connect-timeout 2 --max-time 5 \
      "https://$controller:8443/whoAmI/api/json?tree=authenticated"
  ) && [[ "$status" -eq 200 ]]; do
    echo "$controller returned HTTP $status — retrying in 5s..."
    sleep 5
  done
  echo "$controller is healthy (HTTP 200)"
  docker compose -f docker-compose.yaml ps "$controller"
done
