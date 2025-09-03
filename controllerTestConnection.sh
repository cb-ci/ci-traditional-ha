#! /bin/bash

# This script verifies the connection to controller replicas through haproxy and printgs out the active replica and controller (cookie)
# See curl headers: https://daniel.haxx.se/blog/2022/03/24/easier-header-picking-with-curl

# **Netscape cookie file format**
#```
#client.ha    FALSE    /    FALSE    0    cloudbees_sticky    client_controller_1
#```
#
#Let’s break it down field by field:
#
#---
#
#### Netscape cookie file format (7 fields)
#
#1. **Domain** → `client.ha`
#
#   * The host/domain the cookie is valid for.
#   * Requests to `client.ha` (or its subpaths, depending on the `includeSubdomains` flag) will send this cookie.
#
#2. **Include subdomains flag** → `FALSE`
#
#   * If `TRUE`, cookie is valid for all subdomains of `client.ha`.
#   * `FALSE` = only sent to the exact host `client.ha`.
#
#3. **Path** → `/`
#
#   * The URL path scope.
#   * Cookie will be sent for requests to `/` and any subpaths.
#
#4. **Secure flag** → `FALSE`
#
#   * If `TRUE`, cookie only sent over HTTPS.
#   * `FALSE` = cookie may be sent over plain HTTP.
#
#5. **Expiry** → `0`
#
#   * Unix timestamp for expiry.
#   * `0` means a **session cookie** (valid until the client process exits).
#
#6. **Cookie name** → `cloudbees_sticky`
#
#   * The name of the cookie.
#   * In your case, HAProxy (or CloudBees CI OpsCenter ingress) sets this for **sticky session routing**.
#
#7. **Cookie value** → `client_controller_1`
#
#   * The value associated with the cookie name.
#   * Here it encodes the backend (`client_controller_1`) so HAProxy can route subsequent requests to the same Jenkins controller.
#
#---
#
#### ✅ In plain words
#
#This cookie tells the client:
#
#> "When talking to `client.ha/…`, always include `cloudbees_sticky=client_controller_1`, so the load balancer knows to send you back to the same controller instance (`client_controller_1`)."
#
#It’s basically how HAProxy achieves **sticky sessions** for Jenkins controllers in an HA setup.



source ../env.sh
source ../env-ssl.sh

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


