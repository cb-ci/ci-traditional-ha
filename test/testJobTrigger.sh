#! /bin/bash

# This script triggers the test pipeline on the controller and prints the response header
# See curl headers: https://daniel.haxx.se/blog/2022/03/24/easier-header-picking-with-curl

source ../env.sh
source ../env-ssl.sh

JENKINS_TOKEN=${1:-"YOUR_ADMIN_TOKEN"}
if [ $# -eq 1 ]; then
    JENKINS_TOKEN=$1
    echo "Use token $1"
else
    echo "Script must be called with exactly one parameter."
    echo "YOU NEED TO CREATE A ADMIN TOKEN ON THE OPERATIONS CENTER: create on here: http://${OC_URL}/user/${CJOC_LOGIN_USER}/configure"
    echo "Usage: $0 <CJOC_JENKINS_ADMIN_TOKEN>"
    exit 1
fi

JENKINS_USER_TOKEN="${CJOC_LOGIN_USER}:$JENKINS_TOKEN"
#CONTROLLER_URL=http://client.ha
CONTROLLER_URL=https://${CLIENTS_URL}
#JOBNAME: This is the job we want to trigger on the Controller.The job mus exist on Controller root level
JOB=testpipeline
#curl connect_timeout
CONNECT_TIMEOUT=5
# File where to write the header
RESPONSEHEADERS=headers

while true
do
 	echo "#######################################"
	echo "start build of Job: $JOB"
  # trigger our testpipeline

  COOKIE="cookies.txt"
  # save the cookie : -c cookies.txt
  # send the coolie: -b cookies.txt
	curl --connect-timeout  $CONNECT_TIMEOUT \
	 -v -s -IL -o $RESPONSEHEADERS  \
	 -c $COOKIE \
	 -b $COOKIE \
	 -u $JENKINS_USER_TOKEN -X POST \
	 "$CONTROLLER_URL/job/$JOB/build?delay=0sec"

  # check if we got a healthy HTTP response state in the response header
  # Response header gets written by each loop/request in the $RESPONSEHEADERS (heade) file
  if [ -z "$(cat $RESPONSEHEADERS |grep -oE 'HTTP/2 201|HTTP/ 200|HTTP/1.1 201')" ]
  then
      echo "Can not create job, Gateway/Endpoint not available with HTTP state:  $(cat $RESPONSEHEADERS |grep 'HTTP/2') "
      exit 1
	else
	    # read the wanted information like replica host and ip address in variables
	    LOCATION="$(cat $RESPONSEHEADERS        |grep -E "location.*"                  |  awk '{print $2}')"
	    REPLICA="$(cat $RESPONSEHEADERS         |grep -E "x-jenkins-replica-host.*"    |  awk '{print $2}')"
	    REPLICA_IP="$(cat $RESPONSEHEADERS      |grep -E "x-jenkins-replica-address.*" |  awk '{print $2}')"
	    STICKY_COOKIE="$(cat $RESPONSEHEADERS   |grep -E "set-cookie:.*"               |  awk '{print $2}')"
	    echo "LOCATION:                    $LOCATION"
	    echo "CONTROLLER_REPLICA:          $REPLICA"
	    echo "CONTROLLER_REPLICA_IP:       $REPLICA_IP"
	    echo "CONTROLLER_STICKY_COOKIE:    $STICKY_COOKIE"
	    echo "COOKIE: $(cat cookies.txt | grep -oE ${CLIENTS_URL}.*$)"
      #cat $RESPONSEHEADERS && cat $COOKIE
	    #curl -u $JENKINS_USER_TOKEN  -IL $CONTROLLER_URL/api/json?pretty=true
	fi
	sleep $CONNECT_TIMEOUT
done


