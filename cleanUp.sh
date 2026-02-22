#!/bin/bash

source .env

./down.sh
rm -rf ${PERSISTENCE_PREFIX}
rm -rf secrets/agent-ssh-key*
# rm -rf ${SSL_DIR}/*.pem
# rm -rf ${SSL_DIR}/*.csr 
# rm -rf ${SSL_DIR}/*.srl
# rm -rf ${SSL_DIR}/*.key
# rm -rf ${SSL_DIR}/*.crt
# rm -rf ${SSL_DIR}/*.jks 
# rm -rf ${SSL_DIR}/*.p12 
# rm -rf ${SSL_DIR}/cacert



#docker volume ls -q |xargs  docker volume rm

