#!/bin/bash
set -euo pipefail

if [[ -z "${JAVA_HOME:-}" ]]; then
  echo "JAVA_HOME is not set. Set JAVA_HOME first"
  exit 1
else
  echo "JAVA_HOME is set to: $JAVA_HOME"
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL is not installed."
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool is not found in PATH. Ensure $JAVA_HOME/bin is in PATH or keytool is installed."
  exit 1
fi

CACERTS_SRC="$JAVA_HOME/lib/security/cacerts"
if [[ ! -f "$CACERTS_SRC" ]]; then
  echo "Could not find cacerts at $CACERTS_SRC"
  exit 1
fi

echo "#### Copying cacerts from JAVA_HOME"
cp -f -v "$CACERTS_SRC" .
# Ensure we can write to the copied cacerts
chmod 644 ./cacerts

echo "#### Generating openssl.cnf"
cat > openssl.cnf <<EOF
[ req ]
default_bits       = 2048
default_md         = sha256
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_ca
prompt             = no

[ req_distinguished_name ]
C  = US
ST = California
L  = San Francisco
O  = CloudBees
CN = oc.ha

[ req_ext ]
subjectAltName = @alt_names

[ v3_ca ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = oc.ha
DNS.2 = controller.ha
DNS.3 = ha-client-controller-1
DNS.4 = ha-client-controller-2
DNS.5 = ha-client-controller-3
DNS.6 = operations-center
DNS.7 = haproxy
DNS.8 = jaeger.ha
EOF

echo "#### Generating Private Key and Self-Signed Certificate"
# Generates the private key and self-signed cert in one step, non-interactively
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout jenkins.key \
  -out jenkins.crt \
  -config openssl.cnf \
  -extensions v3_ca

echo "#### Converting to PKCS12"
openssl pkcs12 -export \
  -in jenkins.crt \
  -inkey jenkins.key \
  -out jenkins.p12 \
  -name jenkins \
  -password pass:changeit

echo "#### Creating Java KeyStore (jenkins.jks)"
# Remove old keystore if exists
rm -f jenkins.jks
# Import pkcs12 into a new jks (using standard java keytool)
keytool -importkeystore \
  -destkeystore jenkins.jks \
  -deststorepass changeit \
  -srckeystore jenkins.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass changeit \
  -alias jenkins \
  -noprompt

echo "#### Creating HAProxy PEM and Jenkins PEM"
# PEM will be referenced by HAProxy
cat jenkins.crt jenkins.key > haproxy.pem
cat jenkins.crt > jenkins.pem

echo "#### Adding the PEM file to cacerts"
# Remove existing alias if script is run multiple times
keytool -delete -noprompt -alias jenkins -keystore cacerts -storepass changeit 2>/dev/null || true
keytool -import -noprompt -file jenkins.pem -keystore cacerts -storepass changeit -alias jenkins

echo "#### Certificates successfully generated!"
