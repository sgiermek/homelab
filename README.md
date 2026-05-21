HomeLab Core Components

Purpose
This repository stores and maintains the most important HomeLab components — primarily Docker Compose files and related configuration used to run the environment. The repo contains code and configuration only; sensitive data (passwords, keys, database content) must not be committed.

Contents
- docker/            — docker-compose files and service definitions
- configs/           — config templates and examples (no secrets)
- scripts/           — helper scripts for launch/backup/maintenance

Quick start
1. Install Docker and Docker Compose v2.
2. Create environment files from examples:
   cp .env.example .env
   Edit .env and supply secrets locally (do NOT commit .env).
3. Start services:
   docker compose up -d

Secrets handling
- Never commit .env files containing credentials.
- Use .env.example to show required variables without values.
- For secret management consider: HashiCorp Vault, SOPS, git-crypt or using Docker secrets for production.

Backups
- Databases and persistent volumes must be backed up outside the repo.
- Keep small restore/backup scripts in scripts/ but do not store backups in repo.

Backup scripts
- Example backup scripts are under `backups/scripts/` (e.g. `push_ha_backup.sh`, `push_jenkins_backup.sh`).
- Each script uses a shared function-style structure (create_backup) that:
  - copies container data safely to a temporary directory using `docker cp`,
  - compresses the contents into a timestamped tar.gz archive,
  - rotates local archives older than a configurable retention (default: 10 days),
  - uploads the archive to an `rclone` remote and optionally prunes remote older files.
- To run a script (example):
```bash
sudo bash backups/scripts/push_homeassistant_backup.sh
sudo bash backups/scripts/push_jenkins_backup.sh
```

Configuration & overrides
- Scripts support simple environment variable overrides, for example:
```bash
BACKUP_DIR=/opt/homelab/backups/jenkins RETAIN_LOCAL_DAYS=7 bash backups/scripts/push_jenkins_backup.sh
```



