#! /bin/bash

#Download war
VERSION=latest
if [[ ! -f "cloudbees-core-oc.war" ]]; then
  curl -O https://jenkins-downloads.cloudbees.com/cloudbees-core/traditional/operations-center/rolling/war/$VERSION/cloudbees-core-oc.war
fi

export JENKINS_HOME="./jenkins-home-oc"
export JENKINS_URL=https://oc.ha:8443

export KEYSTORE=$(realpath ./jenkins.jks)
export CACERTS=$(realpath ./cacerts)
export KS_PW="changeit"
java \
-Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true \
-DexecutableWar.jetty.disableCustomSessionIdCookieName=true \
-Dcom.cloudbees.jenkins.ha=false \
-Djavax.net.ssl.keyStore=$CACERTS \
-Djavax.net.ssl.keyStorePassword=$KS_PW \
-Djavax.net.ssl.trustStore=$CACERTS \
-Djavax.net.ssl.trustStorePassword=$KS_PW \
-Djavax.net.ssl.trustStoreType=JKS \
-jar cloudbees-core-oc.war \
--httpPort=-1 \
--httpsKeyStore=$KEYSTORE \
--httpsKeyStorePassword=$KS_PW \
--httpsPort=8443