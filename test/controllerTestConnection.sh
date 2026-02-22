#! /bin/bash

# This script verifies the connection to controller replicas through haproxy and printgs out the active replica and controller (cookie)
# See curl headers: https://daniel.haxx.se/blog/2022/03/24/easier-header-picking-with-curl

source .env
# comment/disable when not using ssl
source .env-ssl
#set -x

CONTROLLER_URL=https://${CLIENTS_URL}
#curl connect_timeout
CONNECT_TIMEOUT=5
# File where to write the header
RESPONSEHEADERS=headers

while true
do
 	echo "#######################################"
	echo "verify connection $CONTROLLER_URL "
  # trigger our testpipeline

  COOKIE="cookies.txt"
  # save the cookie : -c cookies.txt
  # send the coolie: -b cookies.txt
	curl --connect-timeout  $CONNECT_TIMEOUT \
	  -s -IL -o $RESPONSEHEADERS  \
	 -c $COOKIE \
	 -b $COOKIE \
	 -X GET \
	 "$CONTROLLER_URL/whoAmI/api/json?tree=authenticated"
  #curl -u $JENKINS_USER_TOKEN  -IL $CONTROLLER_URL/api/json?pretty=true

  # check if we got a healthy HTTP response state in the response header
  # Response header gets written by each loop/request in the $RESPONSEHEADERS (heade) file
  if [ -z "$(cat $RESPONSEHEADERS |grep -oE 'HTTP/2 201|HTTP/ 200|HTTP/1.1 201|HTTP/2 200')" ]
  then
      echo "HTTP state is not healthy:  $(cat $RESPONSEHEADERS |grep 'HTTP/') "
      exit 1
	else
	    # read the wanted information like replica host and ip address in variables
      cat $RESPONSEHEADERS && cat $COOKIE
	fi
	sleep $CONNECT_TIMEOUT
done


