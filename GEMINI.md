# Project Overview: CloudBees CI Traditional HA Demo Lab

This project provides a comprehensive, self-contained **Docker Compose** environment for demonstrating and testing **CloudBees CI Traditional High Availability (active/active)**. It orchestrates an Operations Center (CJOC) and multiple managed controllers behind an **HAProxy** load balancer, supporting both HTTP and HTTPS modes.

## Core Technologies
- **CloudBees CI (Traditional)**: Operations Center (CJOC) and Managed Controllers.
- **Docker Compose**: Orchestration of the entire stack.
- **HAProxy**: Load balancer with sticky sessions and SSL termination/passthrough.
- **CasC (Configuration as Code)**: Automated provisioning of CJOC and Controllers.
- **OpenTelemetry & Jaeger**: Observability and tracing for Jenkins components.
- **Splunk**: Optional log aggregation and monitoring.
- **Webtop**: A containerized browser for accessing the lab without local configuration changes.

## Architecture & Components
- **Operations Center (CJOC)**: The central management layer for Jenkins controllers.
- **Controllers (ha-client-controller-1, 2, 3)**: Replicas running in HA mode, sharing a single `$JENKINS_HOME` but using independent cache directories.
- **HAProxy**: Routes traffic to `oc.ha` (CJOC) or `client.ha` (Controllers). It implements sticky sessions via the `cloudbees_sticky` cookie.
- **SSH Agent**: A dedicated container for running Jenkins builds via SSH.
- **Persistence**: Local host directories are mapped to container volumes (e.g., `./cloudbees_ci_ha_volumes`).

## Key Workflows

### 1. Environment Setup
The environment is initialized via the `up.sh` script, which:
1. Sources `env.sh` (and `env-ssl.sh` if enabled).
2. Scaffolds required persistent volumes on the host.
3. Generates SSH keys for the Jenkins agent.
4. Renders the `docker-compose.yaml` (using `envsubst`).
5. Starts the containers using `docker compose up`.

### 2. Operational Modes
- **HTTP Mode (Default)**: Runs on ports 80 and 8080. Start with `./up.sh`.
- **HTTPS Mode**: Runs on ports 443 and 8443. Requires self-signed certificates.
  - Generate certs: `cd ssl && ./01-createSelfSigned.sh`
  - Start: `./up.sh ssl=true`

### 3. Maintenance Operations
- **Rolling Upgrades**: Use `controllersRollingUpgrade.sh` to perform a zero-downtime upgrade of the controllers.
- **Restarting Controllers**: `restartControllers.sh`.
- **Cleanup**: Use `down.sh` to stop containers and `deleteVolumes.sh` to wipe all data.

## Configuration & Customization
- **Environment Variables**: Managed in `env.sh`. This includes image versions, IP addresses, URLs, and Java/Jenkins options.
- **Load Balancer**: Configured in `haproxy.cfg` (HTTP) and `haproxy-ssl.cfg` (HTTPS).
- **CasC Bundles**:
  - `casc/cjoc/`: Provisions users, licenses, and controller items.
  - `casc/controller/`: Configures HA settings, SSH credentials, agents, and test jobs.

## Building and Running
| Task | Command |
| :--- | :--- |
| **Start (HTTP)** | `./up.sh` |
| **Start (HTTPS)** | `./up.sh ssl=true` |
| **Stop** | `./down.sh` |
| **Cleanup Volumes** | `./deleteVolumes.sh` |
| **Rolling Upgrade** | `./controllersRollingUpgrade.sh` |
| **Check HA Status** | Access `http://client.ha/manage/highAvailability` |

## Development Conventions
- **Template Driven**: Do not modify `docker-compose.yaml` directly; modify the template and use `up.sh` to render it.
- **CasC First**: Prefer configuring Jenkins via YAML bundles in the `casc/` directory rather than the UI.
- **Static IPs**: Containers are assigned static IPs within the `172.47.0.0/24` subnet for consistent networking.
- **Path Consistency**: Use the `PERSISTENCE_PREFIX` defined in `env.sh` for all volume mappings.
