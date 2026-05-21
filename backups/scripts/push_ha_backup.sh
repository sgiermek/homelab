#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# push_ha_backup.sh
# Uses shared function create_backup to copy data out of a container, compress,
# rotate local backups and upload to an rclone remote.

# Configuration (can be overridden by environment variables)
BACKUP_DIR="${BACKUP_DIR:-/opt/homelab/backups/homeassistant}"
PREFIX="homeassistant"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive:backups/ha-backups}"
RETAIN_LOCAL_DAYS="${RETAIN_LOCAL_DAYS:-10}"
RETAIN_REMOTE_AGE="${RETAIN_REMOTE_AGE:-3d}"

create_backup() {
  local container="$1"; shift
  local src_path="$1"; shift
  local backup_dir="$1"; shift
  local prefix="$1"; shift
  local rclone_remote="$1"; shift
  local retain_days="${1:-$RETAIN_LOCAL_DAYS}"
  local retain_remote_age="${2:-$RETAIN_REMOTE_AGE}"

  mkdir -p "$backup_dir"
  local ts archive tmpdir
  ts=$(date +"%Y%m%d%H%M")
  archive="$backup_dir/${prefix}-$ts.bak.tar.gz"
  tmpdir="$backup_dir/${prefix}-tmp-$ts"

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Starting backup: container=$container src=$src_path -> $archive"

  # ensure temporary directory exists and is empty
  rm -rf "$tmpdir"
  mkdir -p "$tmpdir"

  # copy contents from container path into tmpdir (use trailing /. to copy contents)
  docker cp "${container}:${src_path}/." "$tmpdir"

  # compress tmpdir contents (archive only contents, not the tmpdir name)
  tar -czf "$archive" -C "$tmpdir" .

  # cleanup
  rm -rf "$tmpdir"

  # rotate local backups older than retain_days
  find "$backup_dir" -maxdepth 1 -name "${prefix}-*.bak.tar.gz" -mtime +"$retain_days" -delete || true

  # upload
  echo "Uploading $archive to $rclone_remote"
  rclone copy "$archive" "$rclone_remote"

  # optional: delete remote older than retain_remote_age
  rclone delete "$rclone_remote" --min-age "$retain_remote_age" || true

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Backup completed: $archive"
}

# Run backup for Home Assistant
create_backup "homeassistant" "/config/backups" "$BACKUP_DIR" "$PREFIX" "$RCLONE_REMOTE" "$RETAIN_LOCAL_DAYS" "$RETAIN_REMOTE_AGE"
