#!/bin/bash

set +x

echo "#### SSH Key settings"
# An SSH key gets generated under this path when you run up.sh
export SSH_KEY_ID="agent_id_rsa"
export SSH_PRIVATE_KEY_PATH="secrets/$SSH_KEY_ID"
export SSH_PUBLIC_KEY_PATH="secrets/$SSH_KEY_ID.pub"

#export SSH_PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"
#export SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_rsa.pub"


########################################################################################################################

echo "#### Docker image settings"
#export DOCKER_IMAGE_CLOUDBEES_TAG=latest-jdk21
#export DOCKER_IMAGE_CLOUDBEES_TAG=2.479.3.2-jdk21
export DOCKER_IMAGE_CLOUDBEES_TAG=2.492.1.3-jdk21
# CB CI version for Operations Center and Controllers
export DOCKER_IMAGE_OC=cloudbees/cloudbees-core-oc:${DOCKER_IMAGE_CLOUDBEES_TAG}
export DOCKER_IMAGE_CLIENT_CONTROLLER=cloudbees/cloudbees-core-cm:${DOCKER_IMAGE_CLOUDBEES_TAG}
# https://hub.docker.com/r/jenkins/ssh-agent
export DOCKER_IMAGE_JENKINS_SSH_AGENT=jenkins/ssh-agent:jdk21 #:jdk17
export DOCKER_IMAGE_HAPROXY=haproxy:alpine
# see https://docs.linuxserver.io/images/docker-webtop/#version-tags
export DOCKER_IMAGE_BROWSER_BOX=lscr.io/linuxserver/webtop:latest

########################################################################################################################

echo "#### Docker network settings"

#### We put static IP addresses for docker containers
export IP_PREFIX=172.47
export HAPROXY_IP=$IP_PREFIX.0.5
export OC_IP=$IP_PREFIX.0.6
export CLIENT1_IP=$IP_PREFIX.0.7
export CLIENT2_IP=$IP_PREFIX.0.8
export AGENT_IP=$IP_PREFIX.0.9
export BROWSER_IP=$IP_PREFIX.0.10

########################################################################################################################

echo "#### DNS/URL/PORT settings"

# Hostnames for Operations Center and Controllers
# The controllers are in HA mode, listening on a single CLIENTS_URL
# HAProxy listens for this URL and load balances between the controllers
export OC_URL=oc.ha
export CLIENTS_URL=client.ha
export HA_PROXY_BIND_PORT=80
export HTTP_PROTOCOL=http
export HTTP_PORT=8080
export HA_PROXY_CONFIG=./haproxy.cfg

########################################################################################################################

echo "#### Docker host volume settings"

#### Paths on Docker host for mapped volumes
export PERSISTENCE_PREFIX=$(pwd)/cloudbees_ci_ha_volumes
export BROWSER_PERSISTENCE=$PERSISTENCE_PREFIX/browser
export HAPROXY_PERSISTENCE=$PERSISTENCE_PREFIX/haproxy
export OC_PERSISTENCE=$PERSISTENCE_PREFIX/oc
export CONTROLLER_PERSISTENCE=$PERSISTENCE_PREFIX/controllers
export CONTROLLER1_CACHES=$PERSISTENCE_PREFIX/controller1_caches
export CONTROLLER2_CACHES=$PERSISTENCE_PREFIX/controller2_caches
export AGENT_PERSISTENCE=$PERSISTENCE_PREFIX/ssh-agent1

########################################################################################################################

echo "#### Controller settings"

#https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/specific-ha-installation-traditional#_jenkins_args
#For Docker we must set JENKINS_OPTS instead of JENKINS_ARGS
export CONTROLLER_JENKINS_OPTS="--webroot=/var/cache/cloudbees-core-cm/war --pluginroot=/var/cache/cloudbees-core-cm/plugins"
#https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/specific-ha-installation-traditional#_java_options
export CONTROLLER_JAVA_OPTS="--add-exports=java.base/jdk.internal.ref=ALL-UNNAMED --add-modules=java.se --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.management/sun.management=ALL-UNNAMED --add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED -Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true -DexecutableWar.jetty.disableCustomSessionIdCookieName=true -Dcom.cloudbees.jenkins.ha=false -Dcom.cloudbees.jenkins.replication.warhead.ReplicationServletListener.enabled=true -Djenkins.plugins.git.AbstractGitSCMSource.cacheRootDir=/var/cache/cloudbees-core-cm/caches/git -Dorg.jenkinsci.plugins.github_branch_source.GitHubSCMSource.cacheRootDir=/var/cache/cloudbees-core-cm/caches/github-branch-source -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC"
# https://docs.cloudbees.com/docs/cloudbees-ci/latest/casc-oc/configure-oc-traditional#_adding_the_java_system_property
# We assign the controller casc bundle directly, comment out if you don't want to use casc
export CONTROLLER_JAVA_OPTS="$CONTROLLER_JAVA_OPTS -Dcore.casc.config.bundle=/var/jenkins_home/cascbundle"
#export CONTROLLER_JAVA_OPTS="$CONTROLLER_JAVA_OPTS -Djenkins.websocket.pingInterval=10"

########################################################################################################################

echo "#### Operations center setting"
export CJOC_JAVA_OPTS="-XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC -Dcom.cloudbees.jenkins.ha=false"
# https://docs.cloudbees.com/docs/cloudbees-ci/latest/casc-oc/configure-oc-traditional#_adding_the_java_system_property
# We assign the cjoc casc bundle, comment out if you don't want to use casc
export CJOC_JAVA_OPTS="$CJOC_JAVA_OPTS -Dcore.casc.config.bundle=/var/jenkins_home/cascbundle"
export CJOC_JENKINS_OPTS=""
# Cjoc login user and password
export CJOC_LOGIN_USER="admin"
export CJOC_LOGIN_PW="admin"

########################################################################################################################








