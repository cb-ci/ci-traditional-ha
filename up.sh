#!/bin/bash
set -euo pipefail

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
# --- Functions ---

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

validate_prerequisites() {
  log "Validating prerequisites"
  if ! command -v docker >/dev/null 2>&1; then
    error "docker' command not found. Please install Docker Desktop."
    exit 1
  fi
  if ! command -v envsubst >/dev/null 2>&1; then
    error "envsubst' command not found. Please install 'gettext'."
    exit 1
  fi
  if [[ ! -f "./license.crt" || ! -f "./license.key" ]]; then
    error "CloudBees CI license files './license.crt' './license.key' not found. Create them or copy them to the current directory"
    exit 1
  fi
}

setup_ssh_keys() {
  log "Managing SSH keys"
  mkdir -p secrets
  # Override SSH key paths to local secrets for demo consistency
  export SSH_PRIVATE_KEY_PATH="$(pwd)/secrets/agent_id_rsa"
  export SSH_PUBLIC_KEY_PATH="$(pwd)/secrets/agent_id_rsa.pub"

  if [[ -f "$SSH_PRIVATE_KEY_PATH" && -f "$SSH_PUBLIC_KEY_PATH" ]]; then
    log "Using existing SSH keys in secrets/"
  else
    log "Generating new SSH keys..."
    ssh-keygen -t rsa -b 2048 -f "$SSH_PRIVATE_KEY_PATH" -N ""
  fi
  export JENKINS_AGENT_SSH_PUBKEY=$(cat "$SSH_PUBLIC_KEY_PATH")
}

create_volume_dirs() {
  log "Creating persistence volumes in $PERSISTENCE_PREFIX"
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

  log "Provision CasC bundles"
  cp -Rf casc/cjoc "$OC_PERSISTENCE/cascbundle/"
  cp -Rf casc/controller "$OC_PERSISTENCE/cascbundle"
  
  log "Inject SSH key for CasC"
  cp -vf "$SSH_PRIVATE_KEY_PATH" "$CONTROLLER_PERSISTENCE/id_rsa"
  chmod 600 "$CONTROLLER_PERSISTENCE/id_rsa"
  
  # Inject SSL certificates for HAProxy
  if [[ "$SSL" == "true" ]]; then
    log "Preparing SSL volumes"
    mkdir -p cloudbees_ci_ha_volumes/haproxy/etc/ssl/certs
    if [[ -f "ssl/haproxy.pem" ]]; then
        cp -v ssl/haproxy.pem cloudbees_ci_ha_volumes/haproxy/etc/ssl/certs/haproxy.pem
    fi
  fi
  
  log "Ensure proper permissions"
  find "$PERSISTENCE_PREFIX" -type d -exec chmod 700 {} +
}

# --- Main Execution ---

validate_prerequisites

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
  log "SSL mode ENABLED"
  if [[ ! -f "./ssl/haproxy.pem" && ! -f "./ssl/jenkins.crt" && ! -f "./ssl/jenkins.key" && ! -f "./ssl/jenkins.p12" ]]; then
    cd ssl
    ./01-createSelfSigned.sh
    cd ..
  fi
  source .env-ssl
  COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.ssl.yaml"
else
  log "SSL mode DISABLED"
fi

# Setup SSH keys
setup_ssh_keys

# Create volume directories
create_volume_dirs



# workaround to avoid https://github.com/testcontainers/testcontainers-java/issues/11222
mkdir -p "${OC_PERSISTENCE}"
cp -f ./license.crt "${OC_PERSISTENCE}/license.crt"
cp -f ./license.key "${OC_PERSISTENCE}/license.key"
chmod 600 "${OC_PERSISTENCE}/license.crt" "${OC_PERSISTENCE}/license.key"
log "Copied license files to ${OC_PERSISTENCE}"

mkdir -p "${OC_PERSISTENCE}/init.groovy.d"
cp -f ./jenkins_init.groovy.d/init_user.groovy "${OC_PERSISTENCE}/init.groovy.d/init_user.groovy"
chmod 644 "${OC_PERSISTENCE}/init.groovy.d/init_user.groovy"
log "Copied init_user.groovy to ${OC_PERSISTENCE}/init.groovy.d"
# sudo chown -R 1000:1000 ${CJOC_PERSISTENCE} ${CONTROLLER_PERSISTENCE} 

log "tarting containers"
docker compose $COMPOSE_FILES up -d --force-recreate

log "Stack is starting. Resources persisted in: $PERSISTENCE_PREFIX"

if ping -c 1 "$OC_URL" > /dev/null 2>&1; then
  log "Host resolution for $OC_URL OK."
  log "Access Operations Center at: ${HTTP_PROTOCOL}://${OC_URL}"
else
  warn "Host resolution failed for $OC_URL. Please update /etc/hosts or use Webtop at http://localhost:3000"
fi
