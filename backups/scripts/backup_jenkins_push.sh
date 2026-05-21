#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# backup_jenkins_push.sh
# Uses create_backup function to copy Jenkins data out of container, compress,
# rotate local backups and upload to rclone remote.

# Configuration (can be overridden by environment variables)
BACKUP_DIR="${BACKUP_DIR:-/opt/homelab/backups/jenkins}"
PREFIX="jenkins"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive:backups/jenkins-backups}"
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

  # prepare tmpdir
  rm -rf "$tmpdir"
  mkdir -p "$tmpdir"

  # copy contents (use trailing /. to copy contents only)
  docker cp "${container}:${src_path}/." "$tmpdir"

  # compress
  tar -czf "$archive" -C "$tmpdir" .

  # cleanup tmpdir
  rm -rf "$tmpdir"

  # rotate local backups
  find "$backup_dir" -maxdepth 1 -name "${prefix}-*.bak.tar.gz" -mtime +"$retain_days" -delete || true

  # upload and remote cleanup
  echo "Uploading $archive to $rclone_remote"
  rclone copy "$archive" "$rclone_remote"
  rclone delete "$rclone_remote" --min-age "$retain_remote_age" || true

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Backup completed: $archive"
}

# Run backup for Jenkins
create_backup "jenkins" "/var/jenkins_home" "$BACKUP_DIR" "$PREFIX" "$RCLONE_REMOTE" "$RETAIN_LOCAL_DAYS" "$RETAIN_REMOTE_AGE"
