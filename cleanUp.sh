#!/bin/bash

source .env

./down.sh
rm -rf ${PERSISTENCE_PREFIX}
#docker volume ls -q |xargs  docker volume rm

