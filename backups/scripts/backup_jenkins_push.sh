#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# backup_jenkins_push.sh
# Backs up Jenkins data using shared create_backup function.

# Source the shared backup library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_backup.sh
source "$SCRIPT_DIR/lib_backup.sh"

# rotate local backups and upload to rclone remote.

# Configuration (can be overridden by environment variables)
BACKUP_DIR="${BACKUP_DIR:-/opt/homelab/backups/jenkins}"
PREFIX="jenkins"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive:backups/jenkins-backups}"
RETAIN_LOCAL_DAYS="${RETAIN_LOCAL_DAYS:-10}"
RETAIN_REMOTE_AGE="${RETAIN_REMOTE_AGE:-3d}"

# Run backup for Jenkins
create_backup "jenkins" "/var/jenkins_home" "$BACKUP_DIR" "$PREFIX" "$RCLONE_REMOTE" "$RETAIN_LOCAL_DAYS" "$RETAIN_REMOTE_AGE"
