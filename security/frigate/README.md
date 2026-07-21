# Frigate

NVR / detekcja obiektów z kamer IP. Na start: 1 kamera, detektor CPU (brak
Coral na hoście), krótki retention na lokalnym dysku (mało wolnego miejsca).

## Status hosta (dusty)

- CPU: Intel i5-2450M (Sandy Bridge) - brak sensownej akceleracji sprzętowej
- Coral: brak - detekcja CPU-only, wolna, nie skaluje się powyżej ~1 kamery
- Dysk: ~35GB wolnego - recording tylko wokół ruchu (`mode: motion`), krótki retain

Docelowo: Coral USB (akceleracja detekcji) + dysk zewnętrzny/NAS pod nagrania
(patrz TODO niżej).

## Setup

```bash
cd /opt/homelab/security/frigate
cp .env.example .env
nano .env            # wpisz prawdziwe hasło do kamery RTSP
nano config/config.yml   # podmień front_door / <user> / <camera-ip> / <stream-path>
docker compose up -d
```

MQTT: korzysta z istniejącego brokera Mosquitto z
`automation/homeassistant` (kontener `mosquitto`, sieć `homelab`) - nie ma
osobnego brokera dla Frigate.

## Dostęp

- UI (przez Caddy, uwierzytelnione): https://frigate.lan
- UI bezpośrednio: http://192.168.10.10:8971
- RTSP restream (go2rtc, np. do VLC): rtsp://192.168.10.10:8554/<camera_name>

Port 5000 (nieuwierzytelniony) i 8555 (WebRTC) celowo nie są publikowane.

## TODO

- [ ] Dodać Coral USB, zmienić `detectors` w `config/config.yml` na `type: edgetpu`
- [ ] Podpiąć dysk zewnętrzny/NAS pod `/media/frigate` (obecnie bind mount do
      `./storage` na dysku systemowym) i wydłużyć retention
- [ ] Dodać kolejne kamery
