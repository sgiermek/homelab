#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# push_ha_backup.sh
# Backs up Home Assistant data using shared create_backup function.

# Source the shared backup library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_backup.sh
source "$SCRIPT_DIR/lib_backup.sh"

# rotate local backups and upload to an rclone remote.

# Configuration (can be overridden by environment variables)
BACKUP_DIR="${BACKUP_DIR:-/opt/homelab/backups/homeassistant}"
PREFIX="homeassistant"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive:backups/ha-backups}"
RETAIN_LOCAL_DAYS="${RETAIN_LOCAL_DAYS:-10}"
RETAIN_REMOTE_AGE="${RETAIN_REMOTE_AGE:-3d}"

# Run backup for Home Assistant
create_backup "homeassistant" "/config/backups" "$BACKUP_DIR" "$PREFIX" "$RCLONE_REMOTE" "$RETAIN_LOCAL_DAYS" "$RETAIN_REMOTE_AGE"
