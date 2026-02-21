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