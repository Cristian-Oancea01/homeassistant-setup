---
name: homeassistant-setup
description: Home Assistant on QNAP NAS — Docker, integrations, Lovelace dashboard, automations
license: MIT
compatibility: opencode
---

## Access

- SSH: `ssh <qnap-user>@<nas-ip>`
- Docker binary: `/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker`
- HA container name: `homeassistant`
- HA config path on NAS: `/share/homeassistant/config/`
- Credentials: stored locally in a secrets file — **never commit**

## Lessons learned (keep updated)

### Lovelace yaml mode
- Set `lovelace: mode: yaml` in `configuration.yaml` — do **not** add `resources:` there
- Resources must be declared in `ui-lovelace.yaml` under a top-level `resources:` key
- `.storage/lovelace_resources` is ignored in yaml mode
- `.storage/lovelace_dashboards` must have `"mode": "yaml"` — if it says `"storage"` the old UI dashboard loads instead
- `.storage/lovelace.lovelace` holds the old storage-mode dashboard — safe to ignore
- **Lovelace yaml changes require a container restart** — file watcher does not detect SMB changes

### Container restart
```bash
ssh <qnap-user>@<nas-ip> \
  "/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker restart homeassistant"
# Wait ~45s, then check logs:
ssh <qnap-user>@<nas-ip> \
  "/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker logs --tail 10 homeassistant 2>&1"
```

### Custom cards not loading ("configuration error" on every card)
Two causes found:
1. `resources: []` in `configuration.yaml` blanks out all card JS — remove it
2. `lovelace_dashboards` mode set to `storage` — patch with `sed -i s/storage/yaml/ /share/homeassistant/config/.storage/lovelace_dashboards` (stop container first)

### Mushroom cards
- HACS installs `piitaya/lovelace-mushroom` — single file `mushroom.js`
- Card types: `custom:mushroom-light-card`, `custom:mushroom-entity-card`, `custom:mushroom-title-card`, `custom:mushroom-template-card`, `custom:mushroom-climate-card`, `custom:mushroom-cover-card`, `custom:mushroom-chips-card`
- Card names are NOT visible as literal strings in the minified JS — they are assembled from variables. This is normal.

### ui-lovelace.yaml structure
```yaml
title: Home
resources:
  - url: /hacsfiles/lovelace-mushroom/mushroom.js
    type: module
  - url: /hacsfiles/button-card/button-card.js
    type: module
  - url: /hacsfiles/mini-graph-card/mini-graph-card-bundle.js
    type: module
views:
  - !include lovelace/views/01_home.yaml
  - !include lovelace/views/02_lighting.yaml
  - !include lovelace/views/03_climate.yaml
  - !include lovelace/views/04_ventilation.yaml
  - !include lovelace/views/05_blinds.yaml
  - !include lovelace/views/06_settings.yaml
```

### Komfovent pymodbus fix
- pymodbus 3.11+ renamed `slave=` → `device_id=`
- Fixed in `/config/custom_components/komfovent/modbus.py` — all 4 call sites use `device_id=self._unit`

### Komfovent entity IDs (example — your IDs may differ)
- `climate.komfovent`
- `select.komfovent_current_mode` (options: normal / boost / away)
- `select.komfovent_scheduler_mode`, `select.komfovent_temperature_control`, `select.komfovent_flow_control`, `select.komfovent_eco_heat_recovery`
- `sensor.komfovent_supply_temperature`, `sensor.komfovent_extract_temperature`, `sensor.komfovent_outdoor_temperature`
- `sensor.komfovent_power_consumption` — **instantaneous power in W**
- `sensor.komfovent_heater_power` — instantaneous heater power in W
- `sensor.komfovent_total_ahu_energy`, `sensor.komfovent_total_heater_energy`, `sensor.komfovent_total_recovered_energy` — **lifetime odometer totals in kWh**, NOT daily usage
- `sensor.komfovent_specific_power_input`, `sensor.komfovent_heat_exchanger_efficiency`, `sensor.komfovent_energy_saving`
- **No humidity sensor** — do not add humidity cards or automations unless you have one

### Outdoor temperature
Use `sensor.komfovent_outdoor_temperature` if you have Komfovent — no separate weather integration needed.

### Automations
- Files in `automations/` loaded via `!include_dir_merge_list automations/` — each file is a YAML list
- `automations/existing.yaml` — placeholder for UI-created automations
- Automation IDs used in this repo: `blinds_open_at_sunrise`, `blinds_close_at_sunset`, `blinds_close_on_heat`, `ac_schedule_weekday_morning`, `ac_off_when_window_open`, `good_night_routine`, `konfortvent_away_mode`, `konfortvent_return_home`

### Samsung AC entity IDs (SmartThings integration — example)
- `climate.room_air_conditioner` — modes: off/cool/heat/fan_only/dry/auto
- `sensor.room_air_conditioner_temperatura` — room temperature
- `sensor.room_air_conditioner_putere` — power (W)
- `sensor.room_air_conditioner_energie` — energy (kWh)

### LG AC entity IDs (LG ThinQ / smartthinq_sensors — example)
- `climate.ac_living_sus` — modes: off/dry/auto/fan_only/cool/heat
- `sensor.ac_living_sus_energy_yesterday`, `_this_month`, `_last_month`

### Known broken integrations (deferred)
- **Miele**: `flatdict==4.0.1` fails on Python 3.14 (`pkg_resources` missing) — wait for upstream fix or remove
- **govee_light_ble**: archived repo — remove via HACS UI
- **Vivax AC**: not yet integrated — tinytuya scan → LocalTuya or SmartIR fallback
- **VELUX**: requires KLF200 hardware

### Verifying real entity IDs
```bash
# List all entities of a domain from registry
ssh <qnap-user>@<nas-ip> "docker exec homeassistant grep -o 'sensor.komfovent[a-z_]*' /config/.storage/core.entity_registry | sort -u"
```

## File structure
```
homeassistant-setup/
├── docker-compose.yml              # HA container (host network mode)
├── .env.example                    # copy to .env, fill in your values
├── settings.yaml                   # enable/disable integrations and automations
├── config/
│   ├── configuration.yaml          # main HA config (modular includes)
│   ├── secrets.yaml.example        # copy to secrets.yaml, fill in credentials
│   ├── integrations/
│   │   ├── google_assistant.yaml   # Google Home OAuth config
│   │   ├── cover_groups.yaml       # VELUX "all blinds" group
│   │   ├── groups.yaml             # person/presence groups
│   │   └── vivax_smartir_climate.yaml # Vivax IR fallback (Path B)
│   ├── automations/
│   │   ├── existing.yaml           # placeholder for UI-created automations
│   │   ├── blinds.yaml             # sunrise/sunset/heat automations
│   │   ├── lighting.yaml           # motion lights, welcome home
│   │   ├── climate.yaml            # AC schedule, window guard, good night
│   │   └── ventilation.yaml        # Komfovent humidity/presence
│   ├── scenes/
│   │   └── scenes.yaml             # Morning, Evening, Movie, Night, Away
│   ├── scripts/
│   │   └── good_night.yaml         # Good Night on-demand script
│   └── lovelace/
│       ├── ui-lovelace.yaml        # dashboard assembler
│       └── views/
│           ├── 01_home.yaml        # overview + scene tiles
│           ├── 02_lighting.yaml    # all lights by room
│           ├── 03_climate.yaml     # AC units + temp graph
│           ├── 04_ventilation.yaml # Komfovent full control
│           ├── 05_blinds.yaml      # VELUX covers
│           └── 06_settings.yaml    # automation toggles + system
└── scripts/
    ├── deploy.sh                   # rsync config to QNAP + restart HA
    └── validate.sh                 # YAML syntax check before deploy
```

## Next steps
1. Remove `govee_light_ble` — HACS UI → remove archived repo
2. Generate new Long-Lived Access Token in HA if expired
3. Govee: install `govee_lights_local` HACS, enable LAN in Govee app
4. Vivax: tinytuya scan → if found use LocalTuya, else SmartIR
5. VELUX: requires KLF200 hardware interface
6. Miele: wait for flatdict fix or pin older HA image
