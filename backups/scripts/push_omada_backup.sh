#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# push_omada_backup.sh
# Backs up TP-Link Omada Controller backups using shared create_backup function.

# Source the shared backup library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_backup.sh
source "$SCRIPT_DIR/lib_backup.sh"

# Configuration
CONTAINER_NAME="omada-controller" # <-- UPEWNIJ SIĘ, ŻE TO NAZWA TWOJEGO KONTENERA OMADA
BACKUP_DIR="${BACKUP_DIR:-/opt/homelab/backups/omada}"
PREFIX="omada"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive:backups/omada-backups}"
RETAIN_LOCAL_DAYS="${RETAIN_LOCAL_DAYS:-10}"
RETAIN_REMOTE_AGE="${RETAIN_REMOTE_AGE:-14d}" # Omada ma małe pliki .cfg, możesz trzymać je dłużej na gdrive niż HA (np. 14 dni)

# Path
CONTAINER_SRC_PATH="/opt/tplink/EAPController/data/autobackup"


# run backup
create_backup "$CONTAINER_NAME" "$CONTAINER_SRC_PATH" "$BACKUP_DIR" "$PREFIX" "$RCLONE_REMOTE" "$RETAIN_LOCAL_DAYS" "$RETAIN_REMOTE_AGE"
