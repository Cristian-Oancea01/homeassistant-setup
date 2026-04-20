---
name: homeassistant-setup
description: Home Assistant on QNAP NAS — Docker, integrations, Lovelace dashboard, automations
license: MIT
compatibility: opencode
---

## Sensitive Data Policy

### What counts as sensitive data
- **Personal names** — any first name, surname, or nickname of a real person (e.g. room or device names that include a person's name).
- **Location-specific labels** — street addresses, city names, country-specific terms, or any label that uniquely identifies where someone lives.
- **Language-specific labels** — UI labels, entity names, automation aliases, or comments written in a non-English language (e.g. Romanian, French, Spanish).
- **Credentials and tokens** — passwords, API keys, access tokens, OAuth secrets, IP addresses, MAC addresses, SSID names.
- **Device serial numbers** used as human-readable names (numeric IDs embedded in entity names by integrations are acceptable as-is; avoid adding them to display labels).

### Abstraction rules
- All room names, light names, and device labels must be generic English (e.g. `Bedroom 1`, `Office 2`, `Island Light`, `Desk Lamp`).
- Entity IDs exposed in config files must use generic patterns (e.g. `light.bedroom_1`, `climate.midea_ac_bedroom_1`) and be marked `# replace` where the real ID depends on the user's installation.
- Automation `alias` and `id` fields must be in English and must not reference personal names.
- Never commit `config/secrets.yaml` — only `secrets.yaml.example` with placeholder values.

---

## Access

- SSH: `ssh <qnap-user>@<nas-ip>`
- Docker binary: `/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker`
- HA container name: `home-assistant` (not `homeassistant`)
- HA config path on NAS (host): `/share/Public/HomeAssistantConfig/`
- HA config path inside container: `/config/`
- Container volume mount: `/share/Public/HomeAssistantConfig` → `/config`
- **`ui-lovelace.yaml` lives at `/config/ui-lovelace.yaml` (root), NOT `/config/lovelace/ui-lovelace.yaml`**
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
Three causes found:
1. `resources: []` in `configuration.yaml` blanks out all card JS — remove it
2. `lovelace_dashboards` mode set to `storage` — patch with `sed -i s/storage/yaml/ /share/Public/HomeAssistantConfig/.storage/lovelace_dashboards` (stop container first)
3. Adding `resources:` block to `configuration.yaml` or `ui-lovelace.yaml` **conflicts with HACS** — HACS manages resources via `.storage/lovelace_resources` with `?hacstag=` cache params. Do NOT declare resources in yaml. Leave `lovelace_resources` storage file alone; HACS updates it automatically.

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
  - !include lovelace/views/02_living_room.yaml
  - !include lovelace/views/03_dormitor_sus.yaml
  - !include lovelace/views/04_dormitor_victor.yaml
  - !include lovelace/views/05_office.yaml
  - !include lovelace/views/06_other_rooms.yaml
  - !include lovelace/views/07_ventilation.yaml
  - !include lovelace/views/08_energy.yaml
  - !include lovelace/views/09_automations.yaml
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
- Automation IDs used in this repo: `blinds_open_at_sunrise`, `blinds_close_at_sunset`, `blinds_close_on_heat`, `ac_schedule_weekday_morning`, `ac_off_when_window_open`, `good_night_routine`, `konfortvent_away_mode`, `konfortvent_return_home`, `sunset_island_light`

### Samsung AC entity IDs (SmartThings integration — example)
- `climate.room_air_conditioner` — modes: off/cool/heat/fan_only/dry/auto
- `sensor.room_air_conditioner_temperature` — room temperature
- `sensor.room_air_conditioner_power` — power (W)
- `sensor.room_air_conditioner_energy` — energy (kWh)

### LG AC entity IDs (LG ThinQ / smartthinq_sensors — example)
- `climate.ac_living_room` — modes: off/dry/auto/fan_only/cool/heat
- `climate.office_2_air_conditioner` — Office 2
- `sensor.ac_living_room_energy_yesterday`, `_this_month`, `_last_month`

### Vivax AC entity IDs (Midea AC LAN — local LAN, no cloud after setup)
- `climate.midea_ac_bedroom_1` — Bedroom 1
- `climate.midea_ac_bedroom_2` — Bedroom 2
- Sensor entities follow same prefix pattern: `sensor.midea_ac_bedroom_1_indoor_temperature` etc.
- Integration: **Midea AC LAN** (HACS) — uses NetHome Plus credentials to fetch token once, then fully local
- Added via: Settings → Devices & Services → Add Integration → Midea AC LAN → enter NetHome Plus email/password → auto-discover
- Note: entity IDs include the device serial number prefix (`midea_ac_<id>_<name>`) — after setup, rename in HA UI to generic names

### Known broken integrations (deferred)
- **Miele**: `flatdict==4.0.1` fails on Python 3.14 (`pkg_resources` missing) — wait for upstream fix or remove
- **govee_light_ble**: archived repo — remove via HACS UI

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
│   │   ├── theme.yaml              # iOS theme light/dark based on sun
│   │   └── ventilation.yaml        # Komfovent humidity/presence
│   ├── scenes/
│   │   └── scenes.yaml             # Morning, Evening, Movie, Night, Away
│   ├── scripts/
│   │   └── good_night.yaml         # Good Night on-demand script
│   └── lovelace/
│       ├── ui-lovelace.yaml        # dashboard assembler
│       └── views/
│           ├── 01_home.yaml           # overview + scene tiles
│           ├── 02_living_room.yaml    # lights, AC, room automations
│           ├── 03_dormitor_sus.yaml   # Bedroom 1: Vivax AC, LED toggle, lights
│           ├── 04_dormitor_victor.yaml# Bedroom 2: Vivax AC, LED toggle, lights
│           ├── 05_office.yaml         # Office 1 (Samsung AC), Office 2 (LG AC), lights
│           ├── 06_other_rooms.yaml    # hallway/bathroom/staircase/dressing/storage
│           ├── 07_ventilation.yaml    # Komfovent full control
│           ├── 08_energy.yaml         # all consumption graphs + energy stats
│           └── 09_automations.yaml    # global automation toggles
└── scripts/
    ├── deploy.sh                   # rsync config to QNAP + restart HA
    └── validate.sh                 # YAML syntax check before deploy
```

## Next steps
1. Remove `govee_light_ble` — HACS UI → remove archived repo
2. Generate new Long-Lived Access Token in HA if expired
3. Govee: install `govee_lights_local` HACS, enable LAN in Govee app
4. VELUX: requires KLF200 hardware interface
5. Miele: wait for flatdict fix or pin older HA image
6. After adding Vivax/Midea AC: rename entity IDs in HA UI to generic names (e.g. `bedroom_1`) then update config
