#!/bin/bash

set +x

echo "#### Common SSL Options for Controllers and Cjoc"
# see also https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/how-to-setup-https-within-jetty
#export KEYSTORE="/tmp/jenkins.jks"
export KEYSTORE="/tmp/jenkins.p12"
export TRUSTSTORE="/tmp/cacerts"
# in our case: keyStorePassword = trustStorePassword
export STORE_PW="changeit"
export JENKINS_SSL_OPTS="--httpPort=-1 --httpsKeyStore=$KEYSTORE --httpsKeyStorePassword=$STORE_PW  --httpsPort=8443"
export JAVA_SSL_OPTS="-Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true -DexecutableWar.jetty.disableCustomSessionIdCookieName=true  -Djavax.net.ssl.keyStore=$KEYSTORE -Djavax.net.ssl.keyStorePassword=$STORE_PW  -Djavax.net.ssl.trustStore=$TRUSTSTORE -Djavax.net.ssl.trustStorePassword=$STORE_PW -Djavax.net.ssl.keyStoreType=PKCS12 -Djavax.net.ssl.trustStoreType=PKCS12" # JKS#

########################################################################################################################

#For SSL
export CONTROLLER_JAVA_OPTS="$CONTROLLER_JAVA_OPTS $JAVA_SSL_OPTS"
export CONTROLLER_JENKINS_OPTS="$CONTROLLER_JENKINS_OPTS $JENKINS_SSL_OPTS"


export CJOC_JAVA_OPTS="$CJOC_JAVA_OPTS $JAVA_SSL_OPTS"
export CJOC_JENKINS_OPTS="$CJOC_JENKINS_OPTS $JENKINS_SSL_OPTS"

export HA_PROXY_BIND_PORT=443
export HA_PROXY_CONFIG=./haproxy-ssl.cfg
export HTTP_PROTOCOL=https
export HTTP_PORT=8443
########################################################################








