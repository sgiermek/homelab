#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/opt/homelab/backups/jenkins"
DATE="$(date +%F_%H-%M-%S)"

mkdir -p "$BACKUP_DIR"

docker run --rm \
  -v jenkins_home:/data:ro \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf "/backup/jenkins_home_${DATE}.tar.gz" -C /data .

find "$BACKUP_DIR" -type f -name "jenkins_home_*.tar.gz" -mtime +14 -delete
