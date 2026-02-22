#! /bin/bash

#Download war
VERSION=latest
if [[ ! -f "cloudbees-core-cm.war" ]]; then
  curl -O https://downloads.cloudbees.com/cloudbees-core/traditional/client-master/rolling/war/$VERSION/cloudbees-core-cm.war
fi

export JENKINS_HOME="./jenkins-home-controller"
export JENKINS_URL=https://controller.ha:8444
export KEYSTORE=$(realpath ./jenkins.jks)
export CACERTS=$(realpath ./cacerts)
export KS_PW="changeit"
# #-Djavax.net.debug=ssl
# -Djavax.net.debug=all
java \
-Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true \
-DexecutableWar.jetty.disableCustomSessionIdCookieName=true \
-Dcom.cloudbees.jenkins.ha=false \
-Djavax.net.ssl.keyStore=$CACERTS \
-Djavax.net.ssl.keyStorePassword=$KS_PW \
-Djavax.net.ssl.trustStore=$CACERTS \
-Djavax.net.ssl.trustStorePassword=$KS_PW \
-Djavax.net.ssl.trustStoreType=JKS \
-jar cloudbees-core-cm.war \
--httpPort=-1 \
--httpsKeyStore=$KEYSTORE \
--httpsKeyStorePassword=$KS_PW \
--httpsPort=8444


#-Djavax.net.ssl.keyStore=…/cacerts
#-Djavax.net.ssl.keyStorePassword=…
#-Djavax.net.ssl.trustStore=…/cacerts
#-Djavax.net.ssl.trustStorePassword=…
#-Djavax.net.ssl.trustStoreType=JKS
#…/jenkins.war
#--httpPort=-1
#--httpsKeyStore=…/cacerts
#--httpsKeyStorePassword=…
#--httpsPort=8443