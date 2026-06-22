# HomeLab

## Purpose

This repository contains the infrastructure, configuration, and operational documentation for my HomeLab environment.

The repository stores:

- Docker Compose definitions
- Service configurations
- Reverse proxy configuration
- Backup scripts
- Infrastructure documentation
- Environment templates

The repository contains **configuration only**.

Sensitive information such as:

- passwords
- API keys
- tokens
- certificates
- database contents

must never be committed.

---

# Architecture

## Core Components

| Component | Purpose |
|------------|----------|
| Docker | Container runtime |
| Docker Compose | Service orchestration |
| Caddy | Reverse proxy + internal TLS |
| dnsmasq | Local DNS resolver |
| Homepage | Service dashboard |
| Portainer | Docker management |
| Grafana | Monitoring and dashboards |
| Home Assistant | Home automation |
| Mosquitto | MQTT broker |
| Zigbee2MQTT | Zigbee integration |
| Omada Controller | Network management |
| Vaultwarden | Password and secret management |

---

# Network Design

## Docker Network

All infrastructure containers are attached to a shared Docker network:

```text
homelab
```

Example:

```yaml
networks:
  homelab:
    external: true
```

Benefits:

- container-to-container communication
- no dependency on host IP addresses
- simpler reverse proxy configuration
- easier service migration

Create network:

```bash
docker network create homelab
```

Inspect:

```bash
docker network inspect homelab
```

---

# DNS Architecture

## Local DNS

Local DNS is provided by dnsmasq.

Configuration:

```ini
local=/lan/
domain=lan
```

## Wildcard DNS

All `*.lan` domains resolve automatically to the HomeLab host:

```ini
address=/.lan/192.168.10.10
```

Example:

```text
links.lan
grafana.lan
ha.lan
omada.lan
vault.lan
anything.lan
```

will all resolve to:

```text
192.168.10.10
```

Benefits:

- no manual DNS entries
- adding a new service requires only a Caddy route
- consistent local naming convention

Test:

```bash
resolvectl query vault.lan
```

---

# Reverse Proxy

## Caddy

All public HomeLab services are exposed through Caddy.

Examples:

```text
https://links.lan
https://grafana.lan
https://ha.lan
https://omada.lan
https://vault.lan
```

Example route:

```caddy
vault.lan {
    reverse_proxy vaultwarden:80
}
```

Services running inside Docker should be referenced by container name:

```caddy
grafana.lan {
    reverse_proxy grafana:3000
}
```

Services outside Docker can still be proxied using IP:

```caddy
slzb.lan {
    reverse_proxy 192.168.30.50
}
```

---

# Internal TLS

Caddy automatically generates local certificates.

Global configuration:

```caddy
{
    local_certs
}
```

Benefits:

- HTTPS everywhere
- no self-signed certificate management
- automatic certificate renewal

---

# Service Onboarding

When adding a new service:

## 1. Connect service to homelab network

```yaml
networks:
  - homelab
```

## 2. Add reverse proxy entry

Example:

```caddy
service.lan {
    reverse_proxy service-container:8080
}
```

## 3. Reload Caddy

```bash
docker restart reverse-proxy
```

## 4. Verify DNS

```bash
resolvectl query service.lan
```

## 5. Add service to Homepage

```yaml
- Service:
    href: https://service.lan
```

No DNS changes are required because wildcard DNS handles all `.lan` domains.

---

# Secrets Management

## Rules

Never commit:

- passwords
- API keys
- access tokens
- certificates
- `.env`

Use:

```text
.env.example
```

to document required variables.

## Vaultwarden

Vaultwarden is used for:

- passwords
- API tokens
- service credentials
- recovery codes
- infrastructure secrets

---

# Environment Files

Example:

```bash
cp .env.example .env
```

Edit locally:

```bash
nano .env
```

Never commit:

```text
.env
```

Commit:

```text
.env.example
```

---

# Backups

## Principles

Persistent data must be backed up outside the repository.

Repository contains:

- backup scripts
- backup documentation
- restore procedures

Repository must not contain:

- backup archives
- databases
- volume contents

---

# Backup Scripts

Location:

```text
backups/scripts/
```

Examples:

```bash
sudo bash backups/scripts/push_homeassistant_backup.sh
sudo bash backups/scripts/push_jenkins_backup.sh
```

Each script:

1. Creates temporary snapshot
2. Copies container data using `docker cp`
3. Creates timestamped archive
4. Removes old local backups
5. Uploads archive using rclone
6. Optionally removes old remote backups

---

# Backup Overrides

Example:

```bash
BACKUP_DIR=/opt/homelab/backups/jenkins \
RETAIN_LOCAL_DAYS=7 \
bash backups/scripts/push_jenkins_backup.sh
```

---

# Recommended Directory Structure

```text
/opt/homelab
├── automation/
│   └── homeassistant/
├── infrastructure/
│   ├── homepage/
│   ├── reverse-proxy/
│   ├── grafana/
│   └── portainer/
├── networking/
│   └── omada/
├── security/
│   └── vaultwarden/
├── backups/
│   └── scripts/
└── docs/
```

---

# Operational Commands

## Containers

```bash
docker ps
```

```bash
docker compose up -d
```

```bash
docker compose down
```

## Network

```bash
docker network inspect homelab
```

## DNS

```bash
resolvectl query vault.lan
```

```bash
dig vault.lan
```

## Reverse Proxy

```bash
docker logs reverse-proxy
```

```bash
docker restart reverse-proxy
```

---

# Design Principles

- Infrastructure as Code
- HTTPS by default
- Wildcard local DNS
- Shared Docker network
- Secrets outside Git
- Automated backups
- Service discovery through DNS
- Minimal host dependencies
- Container-first architecture
