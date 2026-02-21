#! /bin/bash

cp -v $JAVA_HOME/lib/security/cacerts .
cat jenkins.crt jenkins.key > jenkins.pem
#keytool -delete -noprompt -alias jenkins -keystore cacerts -storepass changeit
keytool -import -noprompt -keystore cacerts -file jenkins.pem -storepass changeit -alias jenkins;