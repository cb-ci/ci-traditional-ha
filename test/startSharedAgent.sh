#! /bin/bash

export SECRET=${1:-"YOUR_AGENT_SECRET"}
curl -kO https://oc.ha/jnlpJars/agent.jar
chmod 755 agent.jar
# In case using HTTP
export JAVA_OPTS=""
# In case using HTTPS TLS
export JAVA_OPTS="-Djava.security.debug=jca  -Djavax.net.debug=ssl,handshake  -Djavax.net.ssl.trustStore=$(pwd)/../ssl/cacerts -Djavax.net.ssl.trustStorePassword=changeit"

export JAVA_TOOL_OPTIONS=$JAVA_OPTS
java -jar agent.jar -url https://oc.ha/ -name mySharedAgent  -webSocket  -secret ${SECRET} -workDir /tmp
#java -Djavax.net.ssl.keyStore=$(pwd)/../ssl/cacerts -Djavax.net.ssl.keyStorePassword=changeit  -Djavax.net.ssl.trustStore=$(pwd)/../ssl/cacerts -Djavax.net.ssl.trustStorePassword=changeit  -jar agent.jar -url https://client.ha/ -secret ${SECRET}   -name "mytest" -webSocket  -workDir "/tmp/"
