#! /bin/bash

source ./env.sh
docker compose restart ha-client-controller-1
#docker compose stop ha-client-controller-1
docker compose restart ha-client-controller-2