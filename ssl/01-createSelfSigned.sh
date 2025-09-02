#! /bin/bash

if [[ -z "${JAVA_HOME}" ]]; then
  echo "JAVA_HOME is not set. Set JAVA_HOME first"
  exit 1
else
  echo "JAVA_HOME is set to: $JAVA_HOME"
fi


if command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL is installed."
else
  echo "OpenSSL is not installed."
  exit 1
fi


# copy cacerts from JAVA_HOME
cp -f -v $JAVA_HOME/lib/security/cacerts .

# Generate a self-seigned TLS certificate, with a subject alternative name matching two additional hostnames:

## Create a file named openssl.cnf for the CSR

cat > openssl.cnf <<EOF
[ req ]
default_bits       = 2048
default_md         = sha256
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_ca

[ req_distinguished_name ]
countryName                 = Country Name (2 letter code)
countryName_default         = US
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = California
localityName                = Locality Name (eg, city)
localityName_default        = San Francisco
organizationName            = CloudBees
organizationName_default    = CloudBees
commonName                  = oc.ha
commonName_default          = oc.ha

[ req_ext ]
subjectAltName = @alt_names

[ v3_ca ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1   = oc.ha
DNS.2   = client.ha
DNS.3   = ha-client-controller-1
DNS.4   = ha-client-controller-2
DNS.5  =  ha-client-controller-3
DNS.6   = operations-center
DNS.7   = haproxy
EOF


## Generate a Private Key
openssl genpkey -algorithm RSA -out jenkins.key -pkeyopt rsa_keygen_bits:2048

## Generate a Certificate Signing Request (CSR)
openssl req -new -key jenkins.key -out jenkins.csr -config openssl.cnf

## Generate a Self-Signed Certificate
openssl x509 -req -days 365 -in jenkins.csr -signkey jenkins.key -out jenkins.crt -extensions v3_ca -extfile openssl.cnf

## Create a Java KeyStore (JKS) to hold the key, and delete the default jenkins alias
keytool -genkey -alias jenkins -keystore jenkins.jks -keyalg rsa

# choose blank values, and for question "Is CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown correct?" answer "yes", as we are deleting this one
keytool -delete -alias jenkins -keystore jenkins.jks

## Convert PEM and add it to the jenkins.jks (Java KeyStore)
openssl pkcs12 -export -in jenkins.crt -inkey jenkins.key -out jenkins.p12 -name jenkins -CAfile jenkins.crt -caname root

# enter a password when prompted, for example 'changeit'
keytool -importkeystore -destkeystore jenkins.jks -srckeystore jenkins.p12 -srcstoretype PKCS12 -storepass changeit -alias jenkins
# enter the same password when prompted, for example 'changeit'

# Now you have a jenkins.jks that can be used for TLS on each replica

# create pem file, includes private key and certificate
# PEM  will be referenced by HApproxy and by the patched cacerts
cat jenkins.crt jenkins.key > haproxy.pem
cat jenkins.crt > jenkins.pem
# Add the pem file to the cacerts
#keytool -delete -noprompt -alias jenkins -keystore cacerts -storepass changeit
keytool -import -noprompt -keystore cacerts -file jenkins.pem -storepass changeit -alias jenkins


