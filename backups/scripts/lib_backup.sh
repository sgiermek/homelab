#!/usr/bin/env bash
# lib_backup.sh
# Shared backup library with create_backup function.
# Source this file in your backup scripts to use create_backup().

set -euo pipefail
IFS=$'\n\t'

# create_backup CONTAINER SRC_PATH BACKUP_DIR PREFIX RCLONE_REMOTE [RETAIN_LOCAL_DAYS] [RETAIN_REMOTE_AGE]
#
# Safely backs up a directory from a running container:
#   1. Creates a temporary directory
#   2. Copies container source path to tmpdir
#   3. Compresses contents into a timestamped tar.gz archive
#   4. Rotates (deletes) local archives older than RETAIN_LOCAL_DAYS (default: 10)
#   5. Uploads archive to rclone remote
#   6. Optionally deletes remote files older than RETAIN_REMOTE_AGE (default: 3d)
#
# Parameters:
#   CONTAINER              - Docker container name (e.g., "homeassistant")
#   SRC_PATH               - Path inside container to back up (e.g., "/config/backups")
#   BACKUP_DIR             - Local directory to store archives
#   PREFIX                 - Prefix for archive filename (e.g., "homeassistant")
#   RCLONE_REMOTE          - Rclone remote path (e.g., "gdrive:backups/ha-backups")
#   RETAIN_LOCAL_DAYS      - (optional) Delete local archives older than N days (default: 10)
#   RETAIN_REMOTE_AGE      - (optional) Delete remote files older than this (rclone duration, default: "3d")
#
# Environment variables (fallback defaults):
#   RETAIN_LOCAL_DAYS      - Fallback for local retention (default: 10)
#   RETAIN_REMOTE_AGE      - Fallback for remote retention (default: "3d")
#
# Example:
#   source "$(dirname "$0")/lib_backup.sh"
#   create_backup "homeassistant" "/config/backups" "/opt/homelab/backups/ha" "homeassistant" "gdrive:backups/ha-backups"
#
create_backup() {
  local container="$1"; shift
  local src_path="$1"; shift
  local backup_dir="$1"; shift
  local prefix="$1"; shift
  local rclone_remote="$1"; shift
  local retain_days="${1:-${RETAIN_LOCAL_DAYS:-10}}"
  local retain_remote_age="${2:-${RETAIN_REMOTE_AGE:-3d}}"

  mkdir -p "$backup_dir"
  local ts archive tmpdir
  ts=$(date +"%Y%m%d%H%M")
  archive="$backup_dir/${prefix}-$ts.bak.tar.gz"
  tmpdir="$backup_dir/${prefix}-tmp-$$-$ts"

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Starting backup: container=$container src=$src_path -> $archive"

  # ensure temporary directory exists and is empty
  rm -rf "$tmpdir"
  mkdir -p "$tmpdir"

  # copy contents from container path into tmpdir (use trailing /. to copy contents only)
  docker cp "${container}:${src_path}/." "$tmpdir"

  # compress tmpdir contents (archive only contents, not the tmpdir name itself)
  tar -czf "$archive" -C "$tmpdir" .

  # cleanup tmpdir
  rm -rf "$tmpdir"

  # rotate local backups older than retain_days
  find "$backup_dir" -maxdepth 1 -name "${prefix}-*.bak.tar.gz" -mtime +"$retain_days" -delete || true

  # upload to rclone remote
  echo "Uploading $archive to $rclone_remote"
  rclone copy "$archive" "$rclone_remote"

  # optional: delete remote files older than retain_remote_age
  rclone delete "$rclone_remote" --min-age "$retain_remote_age" || true

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Backup completed: $archive"
}

