FROM jenkins/inbound-agent:latest-alpine3.21-jdk21
WORKDIR /usr/local/bin

ENV DOCKER_VERSION=18.06.1-ce KUBECTL_VERSION=v1.20 HELM_VERSION=v3.0 JQ_VERSION=1.6

USER root
RUN apk add --no-cache make \
    ca-certificates \
    bash \
    curl \
    diffutils \
    jq \
    yq \
    git

RUN echo $PATH
