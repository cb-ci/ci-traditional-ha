#!/bin/bash
set -euo pipefail

# --- Functions ---

validate_prerequisites() {
  echo "#### Validating prerequisites"
  if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: 'docker' command not found. Please install Docker Desktop."
    exit 1
  fi
  if ! command -v envsubst >/dev/null 2>&1; then
    echo "ERROR: 'envsubst' command not found. Please install 'gettext'."
    exit 1
  fi
}

setup_ssh_keys() {
  echo "#### Managing SSH keys"
  mkdir -p secrets
  # Override SSH key paths to local secrets for demo consistency
  export SSH_PRIVATE_KEY_PATH="$(pwd)/secrets/agent_id_rsa"
  export SSH_PUBLIC_KEY_PATH="$(pwd)/secrets/agent_id_rsa.pub"

  if [[ -f "$SSH_PRIVATE_KEY_PATH" && -f "$SSH_PUBLIC_KEY_PATH" ]]; then
    echo "Using existing SSH keys in secrets/"
  else
    echo "Generating new SSH keys..."
    ssh-keygen -t rsa -b 2048 -f "$SSH_PRIVATE_KEY_PATH" -N ""
  fi
  export JENKINS_AGENT_SSH_PUBKEY=$(cat "$SSH_PUBLIC_KEY_PATH")
}

create_volume_dirs() {
  echo "#### Creating persistence volumes in $PERSISTENCE_PREFIX"
  mkdir -p "$BROWSER_PERSISTENCE"
  mkdir -p "$OC_PERSISTENCE/cascbundle"
  mkdir -p "$CONTROLLER_PERSISTENCE/cascbundle"
  mkdir -p "$AGENT_PERSISTENCE"
  
  # Create controller caches
  for i in 1 2; do
    local cache_dir_var="CONTROLLER${i}_CACHES"
    local cache_dir="${!cache_dir_var}"
    mkdir -p "${cache_dir}/caches/git"
    mkdir -p "${cache_dir}/caches/github-branch-source"
    mkdir -p "${cache_dir}/plugins"
    mkdir -p "${cache_dir}/war"
  done

  # Provision CasC bundles
  cp -Rf casc/cjoc/*.yaml "$OC_PERSISTENCE/cascbundle/"
  cp -Rf casc/controller/*.yaml "$CONTROLLER_PERSISTENCE/cascbundle/"
  
  # Inject SSH key for CasC
  cp -vf "$SSH_PRIVATE_KEY_PATH" "$CONTROLLER_PERSISTENCE/id_rsa"
  chmod 600 "$CONTROLLER_PERSISTENCE/id_rsa"
  
  # Inject SSL certificates for HAProxy
  if [[ "$SSL" == "true" ]]; then
    echo "#### Preparing SSL volumes"
    mkdir -p cloudbees_ci_ha_volumes/haproxy/etc/ssl/certs
    if [[ -f "ssl/jenkins.pem" ]]; then
        cp -v ssl/jenkins.pem cloudbees_ci_ha_volumes/haproxy/etc/ssl/certs/haproxy.pem
    fi
  fi
  
  # Ensure proper permissions
  find "$PERSISTENCE_PREFIX" -type d -exec chmod 700 {} +
}

# --- Main Execution ---

validate_prerequisites

echo "#### Sourcing environment settings"
source .env

SSL=false
COMPOSE_FILES="-f docker-compose.yaml"

for arg in "$@"; do
  if [[ "$arg" == "ssl=true" ]]; then
    SSL=true
    break
  fi
done

if [[ "$SSL" == "true" ]]; then
  echo "SSL mode ENABLED"
  if [[ ! -f "./ssl/haproxy.pem" && ! -f "./ssl/jenkins.crt" && ! -f "./ssl/jenkins.key" && ! -f "./ssl/jenkins.p12" ]]; then
    cd ssl
    ./01-createSelfSigned.sh
    cd ..
  fi
  source ./env-ssl
  COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.ssl.yaml"
else
  echo "SSL mode DISABLED"
fi

# Setup SSH keys
setup_ssh_keys

# Create volume directories
create_volume_dirs

echo "#### starting containers"
docker compose $COMPOSE_FILES up -d --force-recreate

echo "#### Stack is starting. Resources persisted in: $PERSISTENCE_PREFIX"

if ping -c 1 "$OC_URL" > /dev/null 2>&1; then
  echo "Host resolution for $OC_URL OK."
  echo "Access Operations Center at: ${HTTP_PROTOCOL}://${OC_URL}"
else
  echo "Host resolution failed for $OC_URL. Please update /etc/hosts or use Webtop at http://localhost:3000"
fi
