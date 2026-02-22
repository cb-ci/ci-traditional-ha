#!/usr/bin/env bash
#set -euo pipefail
set -x

source .env
# comment/disable when not using ssl
source .env-ssl

export DOCKER_IMAGE_CLOUDBEES_CONTROLLER_TAG=2.516.2.28991-jdk21
# Enable line below to upgrade Controller to the same version as CJOC
#export DOCKER_IMAGE_CLOUDBEES_CONTROLLER_TAG=${DOCKER_IMAGE_CLOUDBEES_CJOC_TAG}

export DOCKER_IMAGE_CLIENT_CONTROLLER=cloudbees/cloudbees-core-cm:${DOCKER_IMAGE_CLOUDBEES_CONTROLLER_TAG}

export logLine="cb-ci"
export VERSION_TXT_PATH=$(pwd)/cloudbees_ci_ha_volumes/controllers/com.cloudbees.jenkins.replication.warhead.ReplicationServletListener.version.txt

for controller in $(docker compose config --services |grep "ha-client*");do
  echo "Processing $controller"

  # Pull and recreate only this service
  docker compose -f docker-compose.yaml pull "$controller"
  #docker compose -f docker-compose.yaml.template up -d --no-deps "$controller"
  #sleep 20
  if [ -f "$VERSION_TXT_PATH" ]
  then
    rm -v $VERSION_TXT_PATH
  fi
  docker compose -f docker-compose.yaml up -d --no-deps "$controller"

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
