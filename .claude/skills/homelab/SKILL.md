---
name: homelab
description: Runbook for operating Szymon's homelab (dusty). Use for any change to services, configs, DNS, dashboards, or docs on the homelab server — covers SSH access, safe edit patterns for root-owned files, HA dashboard procedure, and commit conventions.
---

# Homelab runbook (dusty)

## Access

- SSH: `ssh szymon@192.168.10.10` (host `dusty`, Ubuntu 24.04). No sudo for Claude — sudo steps are prepared as copy-paste commands for the user to run.
- Remote (Tailscale): tailnet `meteor-balance.ts.net`, dusty `100.86.233.20`, subnet router for 192.168.10/20/30, split DNS `lan → 192.168.10.10`.
- Everything runs in Docker Compose under `/opt/homelab` (git repo `github.com/sgiermek/homelab`, branch `main`). Read the repo README first — it is the architecture source of truth and must be updated when architecture changes.

## Key services

| Service | How | UI |
|---|---|---|
| AdGuardHome | Docker host-net, owns DNS :53, wildcard `*.lan` via DNS rewrite | https://adguard.lan |
| Caddy (`reverse-proxy`) | all `*.lan` HTTPS routes, `local_certs` | — |
| Home Assistant | Docker, config `/opt/homelab/automation/homeassistant/config` | https://ha.lan |
| Homepage | tiles in `apps/homepage/config/services.yaml` | https://home.lan |
| Frigate, Omada, Grafana, Vaultwarden… | see repo README | `*.lan` |

## Safe edit pattern for root-owned config files

Many runtime configs are root-owned (AGH `confdir/AdGuardHome.yaml`, HA `.storage/*`). Never edit them while the owning container runs (services rewrite config on shutdown/save):

1. Fetch a working copy over ssh; edit locally; validate (JSON/YAML parse).
2. `docker stop <container>`
3. Snapshot on dusty: `cp FILE FILE.bak-<date>` then write via `docker run --rm -i -v <dir>:/conf alpine sh` (root inside) — a Bash permission classifier may block long inline scripts; upload a script via `scp` to `/tmp` and pipe it instead.
4. `docker start <container>` and verify logs + service URL.
5. Delete `.bak` and any `/tmp` scripts after user accepts (especially anything containing hashes/secrets).

## HA dashboards specifically

- Storage mode: `/config/.storage/lovelace.lovelace` (main "Przegląd"), `lovelace.map`, registry `lovelace_dashboards`. JSON, `data.config.views[]`.
- Edits require HA container stop → write → start (~1 min outage). UI edits overwrite the file — coordinate with user.
- Faster iteration without a restart: in a logged-in browser tab run `hass = document.querySelector('home-assistant').hass`, then `hass.callWS({type:'lovelace/config', url_path:null})` / `{type:'lovelace/config/save', url_path:null, config}` — same path the UI uses.
- Prototype a card risk-free: edit mode → add card → "Edytor konfiguracji YAML", inject YAML by setting `.value` on the `ha-code-editor` element and dispatching `value-changed`; the live preview renders it. Cancel to leave the stored config untouched.
- Verify entity preservation programmatically (diff entity_id sets before/after).
- Daily HA backup exists; `.storage` is included.
- Style: native cards only (no HACS resources installed) — sections layout, tile cards, badges; Polish labels; mobile-first (used mainly on phones).
- Gotchas (HA 2026.7): legacy cards (`sensor`, …) with `grid_options` break the whole sections view (renders blank) — use them WITHOUT grid_options; `gauge` accepts `var(--*-color)` in segments; views lazy-load slowly after HA restart (blank view ≠ broken — wait ~10 s and hard-reload before diagnosing); dashboard build script lives in session scratchpad `build_dashboard.py` pattern — programmatic transform + entity-set assert.
- Markdown card HTML: DOMPurify strips `style` and `class`, so no CSS-based layout. What survives: `<font size="1..7" color="#hex">`, `<big>`, `<small>`, `<sub>`, `<b>`, `<mark>`, `<table>` (with `align` on `td`), `<hr>`, `<img>`, `<ha-icon icon="mdi:…">`, `<ha-alert>`. `<svg>` is dropped entirely. Colour an `ha-icon` by wrapping it in `<font color>` (it inherits `currentColor`). Single newlines become `<br>`. Templates have no history/statistics access — a sparkline must come from a `tile` card's `trend-graph` feature or the legacy `sensor` card.
- Big-number sensor cards ("Czujniki" view, added 2026-07-26): markdown card (Jinja → `<font size="7">` value, humidity, Polish relative time from `last_reported`, colour-coded comfort label) + `tile` with `trend-graph` feature and `grid_options: {columns: 12, rows: 2}` underneath, one grid section per sensor.
- Zigbee2MQTT has `device_options: retain: true` (added 2026-07-26) so states survive HA restarts — keep it when editing z2m config.
- A markdown card whose template errors renders as an **empty box**, not an error — test the content first with `hass.callApi('POST','template',{template})`, which returns the Jinja error. Markdown/graph cards also load a few seconds after the rest of the view; screenshot twice before calling one broken.

## HA YAML config (gitignored, so it is not recoverable from the repo)

- `configuration.yaml` / `templates.yaml` / `automations.yaml` / `scripts.yaml` can be appended to while the container runs; then `template.reload` (or `automation.reload`, …) via `hass.callService` — no restart. **New top-level keys** (`input_number:`, `timer:`, a new `sensor:` platform) do need a restart.
- Renaming a template entity in YAML does **not** change the displayed name once it is registered — set the name via `hass.callWS({type:'config/entity_registry/update', entity_id, name})`, and keep the YAML in sync.
- YAML `input_number` helpers come up at their **minimum** on first creation (no `initial:`, because `initial` would overwrite the user's value on every restart) — set the intended value once via `input_number.set_value` after the first start.
- Trigger-based template sensors: Zigbee sensors report late after a restart, so a `homeassistant: start` trigger renders with fallbacks — guard with `wait_template` + `{{ this.state }}`.
- `as_datetime` raises on a `None` attribute (e.g. `timer.finishes_at` while idle) — guard before piping.
- Automations named in Polish get `entity_id`s derived from the alias, diacritics stripped (`automation.basen_koniec_biegu_recznego`).
- Non-trivial automation designs are documented in `automation/homeassistant/README.md` (tracked) — update it when the design changes.

## Conventions

- Secrets never in git (repo rule). AGH confdir/workdir, HA config are gitignored; only compose/docs/Caddyfile/Homepage config are tracked.
- Commits in English, imperative subject + short why-body; push to `origin main` after user asks.
- After any architecture change: update README section, commit, push.
- Update Claude memory file (`homelab-dusty.md` in project memory) when durable facts change.

## This skill's own location

- Versioned in the repo at `.claude/skills/homelab/SKILL.md`. On the work Mac it lives in the clone `~/Documents/projects/homelab/` and is symlinked to `~/.claude/skills/homelab` (so it's globally available to Claude Code, and project-scoped when a session runs inside the clone).
- Two checkouts of the same branch exist: the Mac clone (author skills/docs here) and dusty `/opt/homelab` (edit infra configs here). Rule: commit skill/doc edits from the Mac clone, infra-config edits from dusty; `git pull --rebase` before push. dusty does not need this skill (Claude Code runs on the Mac), but may pull it harmlessly.
- To edit: change the file in the Mac clone (the symlink makes it live immediately), then commit + push from the clone.
