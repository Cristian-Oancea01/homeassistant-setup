# Home Assistant — Setup Checklist & Entity Reference

Generated: 2026-04-17
Based on: live config at \\192.168.68.106\Public\HomeAssistantConfig

---

## What is already working (do NOT touch)

| Integration | Status | Notes |
|---|---|---|
| Philips Hue | ✅ Working | Bridge at 192.168.68.109, all lights configured |
| Komfovent HRV | ✅ Working | Modbus at 192.168.68.101:502, occasional read errors (normal) |
| Miele Dishwasher | ⚠️ Auth error | Token expired — needs re-auth in Settings → Integrations → Miele |
| Google Cast | ✅ Working | Chromecast + Sony TV Living detected |
| Mobile App | ✅ Working | SM-S918B (Cristian) + SM-S926B (Georgiana) |
| HP Printer | ✅ Working | HP Smart Tank 510 at 192.168.68.123 |
| HACS | ✅ Working | govee_light_ble repo is archived — consider removing |

---

## Real entity IDs (extracted from running system)

### Komfovent (HRV ventilation)
```
climate.komfovent
select.komfovent_current_mode        ← use this for mode changes (not "konfortvent_mode")
select.komfovent_scheduler_mode
select.komfovent_temperature_control
select.komfovent_flow_control
select.komfovent_eco_heat_recovery
```
**Fix needed in `automations/ventilation.yaml`:**
Replace all `select.konfortvent_mode` → `select.komfovent_current_mode`
Replace all `sensor.konfortvent_humidity` → find real humidity sensor (see below)

### Hue lights (all working)
```
light.living_jos          light.living_sus
light.spot_living_1..4    light.bec_living
light.bec_insula_jos      light.bec_insula_sus
light.dormitor_sus        light.dormitor_sus_1  light.dormitor_sus_2
light.dormitor_victor     light.birou_cristi    light.birou_cristi_2
light.birou_georgi        light.hol_sus         light.hol_sus_2
light.baie_sus            light.bec_scara       light.spot_scara_1/2
light.bec_masa_jos        light.bec_masa_sus
light.hue_aurelle_panel_4/5
light.hue_flourish_pendant_1
light.hue_white_lamp_2/3
light.dimmable_light_1    light.dimmable_light_1_2
```

### People (presence)
```
person.cristian_oancea
person.georgiana
```
**Fix needed in `integrations/groups.yaml`:**
Replace `person.resident_1` → `person.cristian_oancea`
Replace `person.resident_2` → `person.georgiana`

### Areas (rooms)
```
living, bucatarie, dormitor, dormitor_sus, dormitor_jos, dormitor_victor
living_sus, living_jos, hol_sus, baie_sus, birou_georgi, birou_cristi
```

---

## What still needs to be set up

### 1. Fix ventilation automations (5 min)
In `automations/ventilation.yaml` on the NAS, fix entity IDs:
- `select.konfortvent_mode` → `select.komfovent_current_mode`
- `sensor.konfortvent_humidity` → need to find the real humidity sensor entity ID

**To find humidity sensor:** HA → Developer Tools → States → filter by `sensor.komfovent` → look for humidity reading.

---

### 2. Fix presence group (2 min)
In `integrations/groups.yaml` on the NAS:
```yaml
all_people:
  name: All People
  entities:
    - person.cristian_oancea
    - person.georgiana
```

---

### 3. Miele re-authentication (5 min)
Settings → Integrations → Miele → Re-authenticate
(Token expired, dishwasher notifications won't fire until fixed)

---

### 4. Samsung AC — not set up yet
The repo assumes `climate.samsung_ac`. Samsung SmartThings integration is NOT installed.

Options:
- **SmartThings cloud**: Settings → Integrations → Add → SmartThings → needs SmartThings account + PAT token
- After setup, find the real entity ID in Developer Tools → States

---

### 5. LG AC — not set up yet
The repo assumes `climate.lg_ac`. LG ThinQ integration is NOT installed.

Options:
- **LG ThinQ (via HACS)**: Install `ha-thinq2` or `smartthinq_sensors` via HACS
- Or use official LG integration if your HA version supports it

---

### 6. Vivax AC — not set up yet
The repo has two paths:
- **Path A (LocalTuya)**: Install LocalTuya via HACS, configure with Tuya device credentials
- **Path B (SmartIR)**: Install SmartIR via HACS + Broadlink IR blaster hardware

LocalTuya is preferred if the Vivax AC has a Tuya chip (most do).

---

### 7. VELUX blinds — not set up yet
The repo assumes `cover.velux_*` entities. VELUX integration is NOT installed.

Steps:
- Install VELUX KLF200 interface (or VELUX Active with Netatmo hub)
- Settings → Integrations → Add → VELUX
- After setup, update `integrations/cover_groups.yaml` with real cover entity IDs

---

### 8. Outdoor temperature sensor — not set up yet
Used by blind heat-protection and AC automations.
The Met.ie weather integration is installed → use `weather.home` or its temperature attribute:
```yaml
# Instead of: sensor.outdoor_temperature
# Use:
sensor.home_temperature   # or check exact entity in Developer Tools
```
Or add a physical outdoor sensor (Hue Outdoor Motion Sensor also provides temperature).

---

### 9. Window sensor — not set up yet
Used by `ac_off_when_window_open` automation.
`binary_sensor.living_room_window` is a placeholder.
If you have no physical window sensor, this automation can be disabled or skipped.

---

### 10. Google Assistant / Google Home — not set up yet
The `integrations/google_assistant.yaml` is present but commented out in `configuration.yaml`.

Prerequisites:
- Public HTTPS endpoint (DuckDNS + Let's Encrypt, or Nabu Casa)
- Google Cloud project with HomeGraph API enabled
- Fill in `secrets.yaml`:
  ```yaml
  ha_external_url: https://your-domain.duckdns.org
  ha_internal_url: http://192.168.68.X:8123
  google_project_id: your-project-id
  ```
- Place `google_credentials.json` in the config folder
- Uncomment `google_assistant: !include integrations/google_assistant.yaml` in `configuration.yaml`

---

### 11. VELUX Lovelace dashboard — after blinds are set up
The lovelace views at `lovelace/views/05_blinds.yaml` use placeholder cover entity IDs.
Apply the full dashboard via: Settings → Dashboards → [dashboard] → Edit → Raw config editor → paste `lovelace/ui-lovelace.yaml`.

---

## Priority order
1. Fix ventilation.yaml entity IDs (Komfovent is working, just wrong names)
2. Fix groups.yaml person entity IDs
3. Fix Miele re-auth (working device, just token expired)
4. Set up Samsung AC (SmartThings) — most used AC
5. Set up LG AC (ThinQ)
6. Set up outdoor temperature sensor (use Met.ie for now)
7. Set up VELUX (requires hardware interface)
8. Set up Vivax AC (requires LocalTuya config)
9. Google Assistant (requires HTTPS public endpoint)
