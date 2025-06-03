Got it! Here's the optimized and verified README.md for your GitHub repo, polished for clarity, accuracy, and professional presentation:

---

# CloudBees Jenkins HTTPS Setup with Self-Signed Certificates on Port 443

This directory contains scripts and resources to help you run CloudBees Jenkins on HTTPS port 443 using self-signed certificates.

---

## Overview

This guide walks you through:

* Downloading necessary CloudBees Jenkins WAR files
* Creating a self-signed certificate including SAN entries
* Configuring Jenkins Controller and Operations Center to run HTTPS using the generated certificates
* Understanding Java keystores and truststores related to SSL/TLS
* Verifying certificates and SANs using keytool and openssl

---

## Resources

| File / Script                                    | Description                                                                                                                                 |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| [00-downloadWar.sh](00-downloadWar.sh)           | Downloads CloudBees Jenkins WAR files for Controller and Operations Center                                                                  |
| [01-createSelfSigned.sh](01-createSelfSigned.sh) | Creates a self-signed certificate (password: `changeit`) producing PEM for HAProxy and Java keystores (`jenkins.jks` and patched `cacerts`) |
| [03-start-CM.sh](03-start-CM.sh)                 | Starts CloudBees Controller on HTTPS port 443 using the `jenkins.jks` keystore                                                              |
| [03-start-OC.sh](03-start-OC.sh)                 | Starts CloudBees Operations Center on HTTPS port 443 using the `jenkins.jks` keystore                                                       |
| [cacerts](cacerts)                               | Java default truststore plus self-signed cert added (used for outbound traffic SSL verification)                                            |
| [jenkins.jks](jenkins.jks)                       | Java keystore with only the self-signed certificate (used by Jenkins for inbound HTTPS connections)                                         |
| [jenkins.pem](jenkins.pem)                       | PEM format certificate and private key for HAProxy frontend SSL                                                                             |

*Note:* The self-signed certificate includes SAN DNS entries (see `../env-ssl.sh`).

---

## Useful Links

* [CloudBees HTTPS Setup with Jetty](https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/how-to-setup-https-within-jetty)
* [Jenkins Reverse Proxy with HAProxy](https://www.jenkins.io/doc/book/system-administration/reverse-proxy-configuration-with-jenkins/reverse-proxy-configuration-haproxy/)
* [Jenkins Initial HTTP/HTTPS Settings](https://www.jenkins.io/doc/book/installing/initial-settings/#configuring-http)
* [SSL Certificates with HAProxy PDF](1_Using_SSL_Certificates_with_HAProxy.pdf)
* [Overview of Java Keystore Types](https://www.pixelstech.net/article/1408345768-Different-types-of-keystore-in-Java----Overview)

---

## Java SSL System Properties

| Property                           | Description                                                       |
| ---------------------------------- | ----------------------------------------------------------------- |
| `javax.net.ssl.keyStore`           | Path to Java keystore file containing private key and certificate |
| `javax.net.ssl.keyStorePassword`   | Password for keystore (also used to decrypt private key)          |
| `javax.net.ssl.trustStore`         | Path to Java truststore file containing trusted CA certificates   |
| `javax.net.ssl.trustStorePassword` | Password for truststore                                           |
| `javax.net.ssl.trustStoreType`     | Optional: type of truststore (default `jks`)                      |
| `javax.net.debug`                  | Enables SSL/TLS debug logging (e.g., `-Djavax.net.debug=ssl`)     |

---

## Downloading a Certificate from a URL

```bash
openssl s_client -showcerts -connect <your-domain>:443 </dev/null 2>/dev/null | openssl x509 -outform PEM > tmpcert.pem
```

---

## Keystore vs Truststore in Java

| Feature                | Keystore                                             | Truststore                                   |
| ---------------------- | ---------------------------------------------------- | -------------------------------------------- |
| Purpose                | Stores private keys and certificates identifying app | Stores certificates trusted for verification |
| Contains Private Keys? | Yes                                                  | No                                           |
| Used By                | Server (or client) presenting its certificate        | Client (or server) verifying remote certs    |
| Default File           | No default; user-specified                           | `cacerts` (default in Java runtime)          |
| System Property        | `javax.net.ssl.keyStore`                             | `javax.net.ssl.trustStore`                   |

Both may be required for mutual TLS authentication.

---

## Certificates Explained

| File          | Purpose                                                                        |
| ------------- | ------------------------------------------------------------------------------ |
| `jenkins.crt` | Public SSL certificate                                                         |
| `jenkins.csr` | Certificate Signing Request to generate a cert                                 |
| `jenkins.jks` | Java Keystore containing private key and cert                                  |
| `jenkins.key` | Private key corresponding to the certificate                                   |
| `jenkins.p12` | PKCS#12 format bundle of key and certificates                                  |
| `jenkins.pem` | PEM format (Base64) certificate and/or key, often for HAProxy or other servers |

---

## Example Commands for Certificate Conversion

* Convert `.p12` to `.jks`:

```bash
keytool -importkeystore -srckeystore jenkins.p12 -srcstoretype pkcs12 -destkeystore jenkins.jks -deststoretype jks
```

* Combine `.crt` and `.key` into `.pem`:

```bash
cat jenkins.crt jenkins.key > jenkins.pem
```

* Convert `.pem` to `.p12`:

```bash
openssl pkcs12 -export -in jenkins.pem -out jenkins.p12 -name "JenkinsCert"
```

---

## SSL/TLS Configuration in Jenkins: `JAVA_OPTS` vs `JENKINS_ARGS`

| Option                                     | Level              | Purpose                                                            |
| ------------------------------------------ | ------------------ | ------------------------------------------------------------------ |
| `JAVA_OPTS="-Djavax.net.ssl.keyStore=..."` | JVM level          | Affects all SSL operations in JVM (plugins, outbound HTTPS, etc.)  |
| `JENKINS_ARGS="--httpsKeyStore=..."`       | Jenkins standalone | Configures keystore Jenkins uses to serve HTTPS in standalone mode |

**Note:**

* For Jenkins running standalone (via `java -jar jenkins.war`), use `--httpsKeyStore` via `JENKINS_ARGS` to enable HTTPS.
* For Jenkins in a servlet container (Tomcat, Jetty), configure SSL via JVM options or container settings.

---

## Verification Commands

### Check SAN entries in `cacerts`:

```bash
keytool -exportcert -keystore cacerts -storepass changeit -alias jenkins -rfc -file cacerts.pem
openssl x509 -in cacerts.pem -text -noout | grep -A 1 "Subject Alternative Name"
```

### Check SAN entries in `jenkins.jks`:

```bash
keytool -exportcert -keystore jenkins.jks -storepass changeit -alias jenkins -file jkscert.pem -rfc
openssl x509 -in jkscert.pem -text -noout | grep -A 1 "Subject Alternative Name"
```

### Verify certificate chain:

```bash
openssl verify -CAfile ca.pem jkscert.pem
```

### Download and verify LB certificate SAN:

```bash
openssl s_client -showcerts -connect <LB_FQDN>:443 </dev/null | openssl x509 -outform PEM > lbcert.pem
openssl x509 -in lbcert.pem -text -noout | grep -A 1 "Subject Alternative Name"
```

---

## Notes

* Default keystore and truststore passwords are `changeit` (unless changed).
* Keep private keys secure and never expose them publicly.
* Adjust keystore paths in the following config files as needed:

  * `/etc/sysconfig/cloudbees-core-cm` (Controller replicas)
  * `/etc/sysconfig/cloudbees-core-oc` (CloudBees Operations Center)

---

Feel free to ask if you want me to also prepare example usage instructions or integration steps!

---

Would you like me to generate the raw `README.md` file content so you can copy-paste it directly?
