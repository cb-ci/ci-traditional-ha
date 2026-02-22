#!/usr/bin/env bash
#
# Script to create and launch a Secure Shared Agent connected to CJOC.
# It uses the CasC bundle management API to provision the agent, retrieves the secret,
# downloads the agent.jar, and launches the agent via JNLP over WebSockets with SSL.

# --- Configuration & Defaults ---
export TOKEN="${TOKEN:-<ADMIN_ID>:<TOKENXXXXXX>}"
export CJOC_URL="${CJOC_URL:-https://oc.ha}"
export SHARED_AGENT_NAME="${SHARED_AGENT_NAME:-SharedAgentTest}"
export SHARED_AGENT_LABEL="${SHARED_AGENT_LABEL:-shared-agent}"
export SHARED_AGENT_REMOTE_FS="${SHARED_AGENT_REMOTE_FS:-/tmp}"
export KEYSTORE_PASSWORD="${KEYSTORE_PASSWORD:-changeit}"
export KEYSTORE_PATH="${KEYSTORE_PATH:-/tmp/jenkins.p12}"
export TRUSTSTORE_PATH="${TRUSTSTORE_PATH:-/tmp/cacerts}"

# --- Helper Functions ---
log() {
  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] INFO: $*"
}

error() {
  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $*" >&2
  exit 1
}

cleanup() {
  # Clean up temporary generation files
  rm -f sharedAgent.yaml agent_secret.groovy
}

# Trap EXIT to always trigger cleanup
trap cleanup EXIT

# --- Validation ---
if [[ "$TOKEN" == "<ADMIN_ID>:<TOKENXXXXXX>" ]]; then
  error "Please set a valid TOKEN environment variable."
fi

# JVM Arguments required for SSL configuration
export VM_ARGS="-Djavax.net.ssl.keyStorePassword=${KEYSTORE_PASSWORD}
  -Djavax.net.ssl.trustStorePassword=${KEYSTORE_PASSWORD}
  -Djavax.net.ssl.keyStore=${KEYSTORE_PATH}
  -Djavax.net.ssl.trustStore=${TRUSTSTORE_PATH}"

log "--------------------------------------------------------"
log " Rendering Shared Agent CasC YAML"
log "--------------------------------------------------------"
cat << EOF > sharedAgent.yaml
removeStrategy:
  rbac: SYNC
  items: NONE
items:
- kind: sharedAgent
  name: ${SHARED_AGENT_NAME}
  description: 'Auto-provisioned Shared Agent for testing'
  displayName: ${SHARED_AGENT_NAME}
  labels: ${SHARED_AGENT_LABEL}
  launcher:
    inboundAgent:
      webSocket: true
      agentStartupOptions: -webSocket
      workDirSettings:
        remotingWorkDirSettings:
          internalDir: remoting
          disabled: false
          failIfWorkDirIsMissing: false
      vmargs: ${VM_ARGS}
  mode: NORMAL
  numExecutors: 1
  remoteFS: ${SHARED_AGENT_REMOTE_FS}
  retentionStrategy:
    sharedNodeRetentionStrategy: {}
EOF

log "YAML payload created successfully."

log "--------------------------------------------------------"
log " Provisioning agent in Operations Center"
log "--------------------------------------------------------"
HTTP_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" --user "$TOKEN" \
  "${CJOC_URL}/casc-items/create-items" \
  -H "Content-Type:text/yaml" \
  --data-binary @sharedAgent.yaml)

if [[ "$HTTP_STATUS" -ne 200 && "$HTTP_STATUS" -ne 204 ]]; then
  error "Failed to create shared agent. HTTP Status: $HTTP_STATUS"
fi
log "Agent CasC bundle applied successfully."

log "--------------------------------------------------------"
log " Retrieving Agent Secret"
log "--------------------------------------------------------"
cat << 'EOF' > agent_secret.groovy
def sharedAgent = Jenkins.getInstance().getItems(com.cloudbees.opscenter.server.model.SharedSlave.class).find { 
  it.launcher != null && 
  it.launcher.class.name == 'com.cloudbees.opscenter.server.jnlp.slave.JocJnlpSlaveLauncher' && 
  it.name == binding.variables.get('SHARED_AGENT_NAME')
}
return sharedAgent?.launcher?.getJnlpMac(sharedAgent)
EOF

AGENT_SECRET=$(curl -k -s -XPOST --data-urlencode "script=$(cat ./agent_secret.groovy)" -L --user "$TOKEN" "$CJOC_URL/scriptText")
AGENT_SECRET=$(echo "$AGENT_SECRET" | sed "s#Result: ##g" | xargs)

if [[ -z "$AGENT_SECRET" || "$AGENT_SECRET" == "null" ]]; then
  error "Failed to retrieve the agent secret. Check script execution or agent name."
fi
log "Agent Secret retrieved successfully: $AGENT_SECRET"

log "--------------------------------------------------------"
log " Initializing Agent Connection"
log "--------------------------------------------------------"
if [[ ! -f "agent.jar" ]]; then
  log "Downloading agent.jar from $CJOC_URL..."
  curl -k -sO "${CJOC_URL}/jnlpJars/agent.jar"
  chmod a+x agent.jar
fi

log "Launching agent..."
java -jar ${VM_ARGS} agent.jar -url "${CJOC_URL}" -name "${SHARED_AGENT_NAME}" -secret "${AGENT_SECRET}" -workDir "${SHARED_AGENT_REMOTE_FS}" -webSocket

