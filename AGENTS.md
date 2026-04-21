# AGENTS.md — Project Reference for AI Agents

Read this file first before exploring any other file in this repo.
It documents the full project structure, dashboard layout, and conventions.
Update this file whenever the project structure, views, or entities change.

**Private entity mappings** (real names, room labels, entity IDs specific to this installation)
are stored in `AGENTS.local.md` on the NAS — never committed.

---

## Project Overview

Home Assistant configuration for a single household.
Deployed via Docker Compose (`docker-compose.yml`).
HA config root: `config/`.
Dashboard: YAML mode (`lovelace.mode: yaml` in `config/configuration.yaml`).

---

## Directory Structure

```
homeassistant-setup/
├── config/
│   ├── configuration.yaml          # Main HA config — wires all includes
│   ├── secrets.yaml.example        # Secrets template (never commit secrets.yaml)
│   ├── automations/
│   │   ├── blinds.yaml             # Sunrise open, sunset close, heat protection
│   │   ├── climate.yaml            # AC schedule, window guard, good night routine
│   │   ├── lighting.yaml           # Motion lights, welcome home
│   │   ├── theme.yaml              # iOS theme light/dark based on sun
│   │   ├── ventilation.yaml        # Komfovent away/return mode
│   │   └── existing.yaml           # Placeholder for UI-exported automations
│   ├── integrations/
│   │   ├── cover_groups.yaml       # VELUX group: cover.all_velux_covers
│   │   ├── groups.yaml             # Presence group: group.all_people
│   │   ├── light_groups.yaml       # HA light groups for desk/shelf combos
│   │   ├── google_assistant.yaml   # Google Home bidirectional (commented out in config)
│   │   └── vivax_smartir_climate.yaml  # SmartIR fallback for Vivax (unused if Midea LAN active)
│   ├── lovelace/
│   │   ├── ui-lovelace.yaml        # Root dashboard — resources + view includes
│   │   └── views/                  # One file per dashboard tab (see Dashboard Layout below)
│   ├── scenes/scenes.yaml          # Scene definitions (mostly via UI)
│   ├── scripts/
│   │   ├── good_night.yaml         # Good Night on-demand script
│   │   └── scripts.yaml            # Additional scripts
│   ├── custom_components/          # HACS components (installed at runtime, not committed)
│   └── www/                        # Custom frontend assets (not committed)
├── docs/
│   └── managing-lights-and-groups.md  # Guide for adding lights/groups via UI or YAML
├── docker-compose.yml
├── settings.yaml
├── .env.example
└── AGENTS.md                       # ← this file (generic only)
```

---

## Dashboard Layout (Lovelace Views)

Tab order and file mapping in `config/lovelace/views/`:

| # | File | Tab Title | Path | Icon |
|---|------|-----------|------|------|
| 01 | `01_home.yaml` | Home | `home` | `mdi:home` |
| 02 | `02_living_room.yaml` | Living Room | `living-room` | `mdi:sofa` |
| 03 | `03_dormitor_sus.yaml` | Bedroom 1 | `bedroom-1` | `mdi:bed-king` |
| 04 | `04_dormitor_victor.yaml` | Bedroom 2 | `bedroom-2` | `mdi:bed` |
| 05 | `05_office.yaml` | Office 1 | `office` | `mdi:desktop-classic` |
| 10 | `10_office_2.yaml` | Office 2 | `office-2` | `mdi:laptop` |
| 06 | `06_other_rooms.yaml` | Other Rooms | `other-rooms` | `mdi:home-floor-1` |
| 07 | `07_ventilation.yaml` | Ventilation | `ventilation` | `mdi:air-filter` |
| 08 | `08_energy.yaml` | Energy | `energy` | `mdi:lightning-bolt` |
| 09 | `09_automations.yaml` | Automations | `automations` | `mdi:robot` |

### View contents summary

- **01 Home** — status chips (outdoor temp, lights on, ACs active, ventilation mode, blinds open), Komfovent summary, quick access cards for key rooms and automations.
- **02 Living Room** — lights (upper/kitchen, main, islands ×2, table ×2, spots ×4, TV), LG AC, room automations (blinds sunrise/sunset/heat, sunset island light).
- **03 Bedroom 1** — Vivax AC (Midea LAN) + temps, LED display toggle, bedroom lights (main, bedside ×2), weekday morning AC automation toggle.
- **04 Bedroom 2** — Vivax AC (Midea LAN) + temps, LED display toggle, room light, weekday morning AC automation toggle.
- **05 Office 1** — Samsung AC (climate card + power/energy sensors), ceiling light, display cabinet/shelf light, shelf lightstrips (upper/lower), desk lamp, PC light bars. Two YAML light groups: desk setup group and shelf group.
- **06 Other Rooms** — Upper Hallway (lights ×2), Upper Bathroom (light), Staircase (main + spots ×2), Dressing Room, Storage Room, VELUX blinds.
- **07 Ventilation** — Komfovent full control: climate card, mode buttons (Normal/Boost/Away), temperature sensors + graph, power + energy graphs, lifetime totals.
- **08 Energy** — all consumption graphs and energy stats: Samsung AC power/energy, LG AC energy (yesterday/month/last month), HRV power + graphs, monthly summary across all ACs.
- **09 Automations** — global house automations (blinds sunrise/sunset/heat, ventilation away/return, AC morning schedule, sunset island light).
- **10 Office 2** — LG AC (climate card + energy this month), ceiling light and pendant lamp.

---

## HACS Frontend Resources (ui-lovelace.yaml)

| Resource | Purpose |
|----------|---------|
| `lovelace-mushroom` | All `custom:mushroom-*` cards |
| `button-card` | `custom:button-card` |
| `mini-graph-card` | `custom:mini-graph-card` |

---

## Integrations

| Integration | Method | Notes |
|-------------|--------|-------|
| Samsung AC | SmartThings | `climate.room_air_conditioner` — replace with your entity ID |
| LG AC (×2) | LG ThinQ | `climate.ac_living_room`, `climate.office_2_air_conditioner` — replace |
| Vivax AC (×2) | Midea AC LAN | `climate.midea_ac_bedroom_1`, `climate.midea_ac_bedroom_2` — replace |
| Komfovent HRV | Custom integration | `climate.komfovent`, `select.komfovent_current_mode`, multiple sensors |
| VELUX blinds | VELUX Active | `cover.velux_*` |
| Philips Hue | Hue bridge | All `light.*` entities, motion sensors |
| Govee | Govee LAN | LED strips and light bars |
| Google Home | Google Assistant | bidirectional — config commented out until credentials added |

---

## All Entities

All entity IDs below are **placeholder templates** — replace with real IDs from HA Developer Tools → States.
Real entity IDs for this installation are documented in `AGENTS.local.md` on the NAS (never committed).

### Climate / AC

| Entity | Device | Location |
|--------|--------|----------|
| `climate.room_air_conditioner` | Samsung AC | Office 1 |
| `climate.ac_living_room` | LG AC (ThinQ) | Living Room |
| `climate.office_2_air_conditioner` | LG AC (ThinQ) | Office 2 |
| `climate.midea_ac_bedroom_1` | Vivax AC (Midea LAN) | Bedroom 1 |
| `climate.midea_ac_bedroom_2` | Vivax AC (Midea LAN) | Bedroom 2 |
| `climate.komfovent` | Komfovent HRV | Whole house |

### Lights — Office 1

| Entity | Description | Notes |
|--------|-------------|-------|
| `light.office_1_ceiling_group` | Hue room group — primary ceiling control | replace |
| `light.office_1_ceiling` | Individual Hue bulb — display shelf/cabinet | replace |
| `light.office_1_shelf_upper` | Upper shelf lightstrip (Govee) | replace |
| `light.office_1_shelf_lower` | Lower shelf lightstrip (Govee) | replace |
| `light.office_1_desk` | Desk lamp (Govee) | replace |
| `light.office_1_pc_bars` | PC light bars (Govee) | replace |
| `light.group_office_1_desk_setup` | HA group: desk + PC bars | light_groups.yaml |
| `light.group_office_1_shelves` | HA group: upper + lower shelf | light_groups.yaml |

### Lights — Office 2

| Entity | Description | Notes |
|--------|-------------|-------|
| `light.office_2_ceiling_group` | Hue room group | replace |
| `light.office_2_pendant` | Hue pendant lamp | replace |

### Lights — Other Rooms

| Entity | Name | Room |
|--------|------|------|
| `light.living_room_upper` | Upper | Living Room Upper |
| `light.kitchen` | Kitchen | Kitchen |
| `light.living_room_main` | Main | Living Room |
| `light.living_room_island_lower` | Island Lower | Living Room |
| `light.living_room_island_upper` | Island Upper | Living Room |
| `light.living_room_table_lower` | Table Lower | Living Room |
| `light.living_room_table_upper` | Table Upper | Living Room |
| `light.spot_living_1` – `light.spot_living_4` | Spots 1–4 | Living Room |
| `light.tv_lights` | TV Lights | Living Room |
| `light.tv_living` | TV | Living Room |
| `light.bedroom_1` | Main | Bedroom 1 |
| `light.bedroom_1_bedside_1` | Bedside 1 | Bedroom 1 |
| `light.bedroom_1_bedside_2` | Bedside 2 | Bedroom 1 |
| `light.bedroom_2` | Main | Bedroom 2 |
| `light.upper_hallway` | Upper Hallway | Upper Hallway |
| `light.upper_hallway_2` | Upper Hallway 2 | Upper Hallway |
| `light.upper_bathroom` | Upper Bathroom | Upper Bathroom |
| `light.staircase_main` | Main | Staircase |
| `light.spot_staircase_1` – `light.spot_staircase_2` | Spots 1–2 | Staircase |
| `light.dressing_room` | Dressing Room | Dressing Room |
| `light.storage_room` | Storage Room | Storage Room |

### Covers (VELUX)

| Entity | Location |
|--------|---------|
| `cover.velux_living_room` | Living Room |
| `cover.velux_bedroom` | Bedroom 1 |
| `cover.velux_kitchen` | Kitchen |
| `cover.velux_office` | Office |
| `cover.all_velux_covers` | Group (all above) |

### Vivax AC — Switches (Midea LAN)

| Entity | Purpose | AC |
|--------|---------|-----|
| `switch.midea_ac_bedroom_1_display` | LED display on/off | Bedroom 1 |
| `switch.midea_ac_bedroom_2_display` | LED display on/off | Bedroom 2 |

> **Sound (beep):** The Midea AC LAN integration does not expose a beep/sound switch. Disabling the beep is not possible without custom firmware or IR blaster.

### Sensors — Samsung AC

| Entity | Meaning |
|--------|---------|
| `sensor.room_air_conditioner_temperature` | Room temperature |
| `sensor.room_air_conditioner_power` | Power (W) |
| `sensor.room_air_conditioner_energy` | Energy total |

### Sensors — LG AC

| Entity | Meaning |
|--------|---------|
| `sensor.ac_living_room_energy_yesterday` | Energy yesterday |
| `sensor.ac_living_room_energy_this_month` | Energy this month |
| `sensor.ac_living_room_energy_last_month` | Energy last month |
| `sensor.office_2_air_conditioner_energy_this_month` | Energy this month (office 2) |

### Sensors — Vivax/Midea AC

| Entity | Meaning |
|--------|---------|
| `sensor.midea_ac_bedroom_1_indoor_temperature` | Indoor temp — Bedroom 1 |
| `sensor.midea_ac_bedroom_1_outdoor_temperature` | Outdoor temp — Bedroom 1 |
| `sensor.midea_ac_bedroom_2_indoor_temperature` | Indoor temp — Bedroom 2 |
| `sensor.midea_ac_bedroom_2_outdoor_temperature` | Outdoor temp — Bedroom 2 |

### Sensors — Komfovent HRV

| Entity | Meaning |
|--------|---------|
| `sensor.komfovent_outdoor_temperature` | Outdoor temperature |
| `sensor.komfovent_supply_temperature` | Supply air temperature |
| `sensor.komfovent_extract_temperature` | Extract air temperature |
| `sensor.komfovent_power_consumption` | Current power (W) |
| `sensor.komfovent_heater_power` | Heater power (W) |
| `sensor.komfovent_total_ahu_energy` | Lifetime AHU energy |
| `sensor.komfovent_total_heater_energy` | Lifetime heater energy |
| `sensor.komfovent_total_recovered_energy` | Lifetime recovered energy |
| `select.komfovent_current_mode` | Current ventilation mode |

### Binary Sensors & Motion

| Entity | Meaning |
|--------|---------|
| `binary_sensor.hue_motion_living_room` | Hue motion — Living Room |
| `binary_sensor.living_room_window` | Window sensor — Living Room |
| `sensor.hue_motion_living_room_illuminance` | Hue lux — Living Room |

### Presence & People

| Entity | Meaning |
|--------|---------|
| `group.all_people` | All residents group |
| `person.resident_1` | Resident 1 |
| `person.resident_2` | Resident 2 |

### Input Booleans

| Entity | Meaning |
|--------|---------|
| `input_boolean.vacation_mode` | Vacation mode toggle |

### Scenes

| Entity | Scene |
|--------|-------|
| `scene.morning` | Morning |
| `scene.movie` | Movie |
| `scene.evening` | Evening |
| `scene.night` | Night |

### Scripts

| Entity | Meaning |
|--------|---------|
| `script.good_night` | Good Night on-demand routine |

### Automations

| Entity | Description | Scope |
|--------|-------------|-------|
| `automation.blinds_open_at_sunrise` | Open blinds 30 min after sunrise | House |
| `automation.blinds_close_at_sunset` | Close blinds at sunset | House |
| `automation.blinds_close_on_heat` | Partial close when outdoor > 28°C | Living Room + Kitchen |
| `automation.ac_schedule_weekday_morning` | Pre-condition bedroom ACs at 06:30 weekdays | Bedroom 1 + 2 |
| `automation.ac_off_when_window_open` | Samsung AC off when window open 5 min | Living Room |
| `automation.good_night_routine` | Lights off, blinds close, AC to 20°C at 23:00 | House |
| `automation.konfortvent_away_mode` | Switch HRV to away mode when everyone leaves | House |
| `automation.konfortvent_return_home` | Switch HRV back to normal on return | House |
| `automation.sunset_island_light` | Turn on island lights at sunset | Living Room |

---

## Conventions

- All entity IDs in committed files use generic English names marked `# replace` — never hardcode real names.
- Never commit `config/secrets.yaml` — only `secrets.yaml.example` is committed.
- Real entity IDs, room names, and person names specific to this installation live in `AGENTS.local.md` on the NAS only.
- Automation files go in `config/automations/` — all files in the dir are merged via `!include_dir_merge_list`.
- Room-specific automations are shown in both the room view and the global Automations tab.
- Vivax LED switch entity pattern: `switch.midea_ac_<device_id>_display`.
- Vivax sound/beep: not supported by Midea AC LAN integration.
