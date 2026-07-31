# Home Assistant

Container: `homeassistant` (compose.yaml in this directory), UI at https://ha.lan.

The runtime config (`automation/homeassistant/config/`) is **gitignored** — it holds secrets, the
recorder database and `.storage/` state. Automations that are non-trivial to reconstruct are
documented here so the design survives outside the daily HA backup.

Config layout inside the ignored directory:

| File | Contents |
|---|---|
| `configuration.yaml` | integrations, helpers (`input_*`, `timer`), YAML platform sensors |
| `templates.yaml` | template sensors / binary sensors (`template: !include`) |
| `automations.yaml` | automations (UI editor rewrites this file) |
| `scripts.yaml` | scripts |
| `.storage/lovelace.lovelace` | dashboards (storage mode — stop the container before editing by hand) |

---

## Pool pump control (added 2026-07-31)

Filtration pump on a Zigbee plug with power metering (`switch.switch_zb_garden`, ~320 W).
Pool 15 m³, pump 10 m³/h → one turnover = 1.5 h. Season roughly June–September, the pool is covered
with a solar foil that heats the surface layer, so filtration also has to mix that heat down.

### Design

Instead of a fixed schedule: a **daily hour budget** plus a controller that picks the best hours.
Self-healing — manual runs count towards the budget, and a restart or power cut does not lose the plan
(`history_stats` recovers from the recorder).

1. **Budget** (`sensor.basen_cel_filtracji`, trigger-based template, recomputed at HA start, 08:00,
   11:00, 14:00 and on correction change):
   `turnovers = clamp(1.0 + (T_water − 16) × 0.16, 1.0 … 3.5)`, `target = 1.5 h × turnovers`,
   plus up to +1 h scaled by the PV day forecast (`energy_production_today / 45 kWh` — a direct proxy
   for how much heat the solar foil collects), +0.5 h when forecast air max ≥ 26 °C, −0.5 h on a
   rainy/cold day, plus the manual correction. Clamped to 1.5–6 h; 0 when water < 12 °C or outside
   April–October.
2. **Timing** (`sensor.basen_start_filtracji`): the block is centred 45 min *after* solar noon, or
   after the PV peak if that falls later — that is when the water under the foil is warmest and PV
   output is high. Clamped into the 09:00–20:00 window.
3. **Decision** (`binary_sensor.basen_zadanie_filtracji`, single source of truth for both the
   controller and the dashboard card; contains `now()` so HA re-renders it every minute):
   auto enabled, no manual timer, budget left, inside the window, and
   (`power_production_now ≥ input_number.basen_prog_pv` and past the planned start, **or** past the
   hard deadline `20:00 − remaining`). A **latch** (`switch` already on) keeps a started run going to
   the end of the budget, so passing clouds and the deadline boundary cannot short-cycle the motor.
4. `automation.basen_kontroler_filtracji` only syncs the switch with the binary sensor (state triggers
   plus a `/15 min` resync, and a branch that stops the pump when the automation is switched off).

There is no inverter integration, so PV comes from the **Forecast.Solar** config entry
(8 kWp / azimuth 180° / declination 37°, free tier = one plane). Open-Meteo (`weather.dom`) exposes
neither cloud cover nor irradiance in its forecast, which is why "how sunny is today" is derived from
the PV energy forecast rather than from `condition`.

### Entities

| Entity | Role |
|---|---|
| `switch.switch_zb_garden` | the pump; `sensor.switch_zb_garden_power` / `_energy` |
| `sensor.pool_sensor_temperature` | water temperature (Zigbee) |
| `sensor.basen_cel_filtracji` | daily target in hours (+ attributes: water/air temp, PV forecast) |
| `sensor.basen_filtracja_dzis` | `history_stats` of pump on-time today |
| `sensor.basen_pozostalo_filtracji` | target − done |
| `sensor.basen_start_filtracji` | planned block start (timestamp) |
| `binary_sensor.basen_zadanie_filtracji` | should the pump run right now |
| `input_boolean.basen_auto` | master switch for the automation |
| `input_number.basen_korekta_h` | manual correction, ±2 h |
| `input_number.basen_prog_pv` | PV power threshold, default 1500 W |
| `timer.basen_reczny` | manual run countdown (pauses the controller) |
| `script.basen_pompa_reczna` / `_stop` | manual run for N minutes / stop |

Automations: `basen_kontroler_filtracji`, `basen_koniec_biegu_recznego`, `basen_awaria_pompy`
(plug on for 3 min while drawing < 100 W → stop the pump, disable the automation, notify),
`basen_plan_filtracji_niewykonany` (21:00 reminder when more than 0.5 h of the budget is left).

### Dashboard

View `Basen` (`/lovelace/pool`, sections layout, native cards only — no HACS resources installed):
water temperature with a 48 h trend, pump / power / automation tiles, quick runs 30 / 60 / 120 min with
a countdown, a "plan for today" markdown table explaining the current decision, tuning sliders, plus
history and energy graphs. The `Basen` heading in the `Ogród` view links to it.

### Operating notes

- Tune without touching YAML: `Korekta czasu` and `Próg mocy PV` on the dashboard.
- "Stop" turns the pump off, but the automation resumes it within ~15 min while budget is left —
  to stop it for longer, turn off `Basen: automatyka filtracji`.
- Turning the pump on by hand while the automation is enabled makes it run until the budget is met
  (the latch), which is intentional.
- The 09:00–20:00 window is hardcoded in three templates (`basen_start_filtracji`, the binary sensor
  and the dashboard markdown card) — change all three together.
- Renaming a template entity in `templates.yaml` does not update the displayed name once the entity is
  registered; rename it in the UI (entity registry) instead.
