Backup

Manual backup:

/opt/homelab/ci/jenkins/scripts/backup-jenkins.sh

Backup location:

/opt/homelab/backups/jenkins
Persistent storage

Docker volume:

docker volume inspect jenkins_home
JCasC

Configuration as Code files:

casc/

Mounted into container:

/var/jenkins_home/casc_configs
