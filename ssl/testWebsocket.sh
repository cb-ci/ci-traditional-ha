#! /bin/bash

HOSTNAME=oc.ha
JENKINS_URL=https://${HOSTNAME}:443

#curl -i -N -H "Connection: Upgrade" \
#    -H "Upgrade: websocket" \
#    -H "Host: oc.ha" \
#    -H "Origin: https://oc.ha" \
#    -H "Sec-WebSocket-Key: KEY==" \
#    -H "Sec-WebSocket-Version: 13" \
#    https://oc.ha/ws
#
#
#  curl --http1.1  -u "admin:XXX"  -i -N -H "Connection: Upgrade" \
#      -H "Upgrade: websocket" \
#      -H "Host: oc.ha" \
#      -H "Origin: https://oc.ha" \
#      -H "Sec-WebSocket-Key: KEY==" \
#      -H "Sec-WebSocket-Version: 13" \
#      https://oc.ha/wscontrollers

#curl --http1.1 -i -N --header "Connection: Upgrade" --header "Upgrade: websocket" \
# --header "Host: $HOSTNAME" --header "Origin: $HOSTNAME" --header "Sec-WebSocket-Key: KEY==" \
# --header "Sec-WebSocket-Version: 13" --header "Secret-Key:SECRET" \
# --header "Node-Name:my-agent" $JENKINS_URL/wscontrollers/

 # --header "X-Remoting-Capability:KEY=" \



#websocat -v --basic-auth "admin:XXXX" wss://oc.ha:443/wsecho/ 2>&1


export KEYSTORE=$(realpath ./jenkins.jks)
export CACERTS=$(realpath ./cacerts)
export KS_PW="changeit"
# #-Djavax.net.debug=ssl
# -Djavax.net.debug=all
java \
-Djavax.net.ssl.keyStore=$CACERTS \
-Djavax.net.ssl.keyStorePassword=$KS_PW \
-Djavax.net.ssl.trustStore=$CACERTS \
-Djavax.net.ssl.trustStorePassword=$KS_PW \
-Djavax.net.ssl.trustStoreType=JKS \
-jar jenkins-cli.jar -auth "admin:XXXXX"  -webSocket -s https://controller.ha/   help
