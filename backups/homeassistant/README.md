# Home Assistant Backup

## 📦 Tworzenie backupu

Backup działa automatycznie przez skrypt `push_ha_backup.sh` i zapisuje konfigurację oraz archiwum w repo GitHub.

### Lokalizacja i nazwy backupów

- Katalog backupów: `/opt/ha-backups`  
- Nazwa backupu: `ha-backup-YYYY-MM-DD_HH-MM.tar.gz`  
- Przykład: `ha-backup-2025-11-30_19-20.tar.gz`

### Ręczne wykonanie backupu

```bash
sudo /opt/ha-backups/push_ha_backup.sh
Skrypt:

Kopiuje /config z kontenera Home Assistant.

Tworzy archiwum .tar.gz.

Dodaje plik do repo Git, robi commit z liczbą zmienionych plików.

Wysyła zmiany do GitHub.

Usuwa backupy starsze niż 10 dni.

Automatyzacja
Backup uruchamiany codziennie przez systemd timer: ha-backup-push.timer

🔄 Odtwarzanie backupu
Uwaga: Przywrócenie backupu nadpisuje aktualną konfigurację.

1. Pobranie backupu
bash
Copy code
cd /opt/ha-backups
git pull origin main
Wybierz backup, np.: ha-backup-2025-11-30_19-20.tar.gz

2. Rozpakowanie backupu
mkdir -p /tmp/ha_restore
tar -xzf /opt/ha-backups/ha-backup-2025-11-30_19-20.tar.gz -C /tmp/ha_restore
3. Zachowanie bieżącej konfiguracji (opcjonalnie)
docker cp homeassistant:/config /opt/ha-backups/config-current-backup
4. Przywrócenie backupu do kontenera
docker cp /tmp/ha_restore/. homeassistant:/config
5. Restart Home Assistant
docker restart homeassistant
6. Sprawdzenie działania
docker logs homeassistant -f
