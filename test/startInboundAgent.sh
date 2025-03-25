#! /bin/bash

#Create an agent node first in controller
export SECRET=${1:-"YOUR_AGENT_SECRET"}
curl -kO https://client.ha/jnlpJars/agent.jar
chmod 755 agent.jar

# In case using HTTP
export JAVA_OPTS=""
# In case using HTTPS TLS
export JAVA_OPTS="-Djava.security.debug=jca  -Djavax.net.debug=ssl,handshake  -Djavax.net.ssl.trustStore=$(pwd)/../ssl/cacerts -Djavax.net.ssl.trustStorePassword=changeit"
# -Djavax.net.ssl.keyStore=$(pwd)/../ssl/cacerts -Djavax.net.ssl.keyStorePassword=changeit  -Djavax.net.ssl.trustStore=$(pwd)/../ssl/cacerts -Djavax.net.ssl.trustStorePassword=changeit
export JAVA_TOOL_OPTIONS=$JAVA_OPTS
java  -jar agent.jar -url https://client.ha/ -secret ${SECRET}  -name "staticInboundAgent" -webSocket  -workDir "/tmp/"