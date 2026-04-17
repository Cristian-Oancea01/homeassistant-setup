# Home Assistant Setup

Modular, plug-and-play Home Assistant configuration for QNAP NAS (Container Station).

**Integrations covered:** Philips Hue · Govee (LAN) · IKEA DIRIGERA · VELUX · Samsung SmartThings · LG ThinQ · Vivax AC · Konfortvent HRV · Google Home (bidirectional)

**Dashboard:** Lovelace with Mushroom cards, Button Card, Simple Thermostat, Mini Graph Card — 6 views: Home, Lighting, Climate, Ventilation, Blinds, Settings.

---

## Repository Structure

```
homeassistant-setup/
├── docker-compose.yml              ← HA container (host network mode)
├── .env.example                    ← copy to .env, fill in your values
├── settings.yaml                   ← enable/disable integrations and automations
├── config/
│   ├── configuration.yaml          ← main HA config (modular includes)
│   ├── secrets.yaml.example        ← copy to secrets.yaml, fill in credentials
│   ├── integrations/
│   │   ├── google_assistant.yaml   ← Google Home OAuth config
│   │   ├── cover_groups.yaml       ← VELUX "all blinds" group
│   │   ├── groups.yaml             ← person/presence groups
│   │   └── vivax_smartir_climate.yaml ← Vivax IR fallback (Path B)
│   ├── automations/
│   │   ├── blinds.yaml             ← sunrise/sunset/heat automations
│   │   ├── lighting.yaml           ← motion lights, welcome home
│   │   ├── climate.yaml            ← AC schedule, window guard, good night
│   │   └── ventilation.yaml        ← Konfortvent humidity/presence
│   ├── scenes/
│   │   └── scenes.yaml             ← Morning, Evening, Movie, Night, Away
│   ├── scripts/
│   │   └── good_night.yaml         ← Good Night on-demand script
│   └── lovelace/
│       ├── ui-lovelace.yaml        ← dashboard assembler
│       └── views/
│           ├── 01_home.yaml        ← overview + scene tiles
│           ├── 02_lighting.yaml    ← all lights by room
│           ├── 03_climate.yaml     ← AC units + temp graph
│           ├── 04_ventilation.yaml ← Konfortvent full control
│           ├── 05_blinds.yaml      ← VELUX covers
│           └── 06_settings.yaml    ← automation toggles + system
└── scripts/
    ├── deploy.sh                   ← rsync config to QNAP + restart HA
    └── validate.sh                 ← YAML syntax check before deploy
```

---

## Quick Start

### Step 1 — Clone this repo

```bash
git clone https://github.com/<your-github-username>/homeassistant-setup.git
cd homeassistant-setup
```

### Step 2 — Configure your properties

```bash
cp .env.example .env
# Edit .env with your QNAP IP, timezone, API keys, etc.

cp config/secrets.yaml.example config/secrets.yaml
# Edit config/secrets.yaml with your passwords and tokens.
# This file is gitignored — never committed.
```

### Step 3 — Enable/disable integrations

Edit `settings.yaml` and set `enabled: true/false` for each integration and automation.

### Step 4 — Deploy the container on QNAP

Copy `docker-compose.yml` to your QNAP at `/share/homeassistant/docker-compose.yml`, then either:

**Option A — Container Station GUI:**
1. QNAP web UI → Container Station → Create → Create Application
2. Paste the contents of `docker-compose.yml`
3. Set application name: `homeassistant`
4. Click Create

**Option B — SSH:**
```bash
ssh admin@<QNAP-IP>
cd /share/homeassistant
docker compose up -d
```

### Step 5 — Deploy config files

```bash
# Validate YAML first
./scripts/validate.sh

# Deploy to QNAP
./scripts/deploy.sh 192.168.1.10 admin /share/homeassistant/config
```

Or manually copy the `config/` folder to `/share/homeassistant/config/` via QNAP File Station.

### Step 6 — First boot

1. Open `http://<QNAP-IP>:8123` in a browser
2. Complete the onboarding wizard (create admin account, set location, timezone)
3. Install HACS (see **HACS Setup** below)
4. Add integrations (see **Integration Setup** below)
5. Apply the dashboard (see **Dashboard** below)

---

## HTTPS Setup (required for Google Home)

Google Home webhook requires a publicly accessible HTTPS endpoint.

### QNAP Application Portal (recommended)

1. QNAP web UI → Control Panel → Application Portal → Reverse Proxy
2. Add rule: Source `https://yourdomain.com:443` → Destination `http://localhost:8123`
3. Control Panel → Security → SSL Certificate → enable Let's Encrypt
4. Forward port 443 on your router to the QNAP IP

Then update `config/secrets.yaml`:
```yaml
ha_external_url: "https://yourdomain.com"
ha_internal_url: "http://<qnap-ip>:<ha-port>"
```

---

## HACS Setup

HACS (Home Assistant Community Store) is required for custom integrations and dashboard cards.

### Install HACS

SSH into QNAP and run:
```bash
docker exec -it homeassistant bash
wget -O - https://get.hacs.xyz | bash -
exit
docker restart homeassistant
```

Then in HA: Settings → Devices & Services → Add Integration → HACS → complete GitHub OAuth.

### Required HACS integrations

Install via HACS → Integrations:

| Integration | Purpose |
|------------|---------|
| `govee_lights_local` | Govee LAN control |
| `velux` | VELUX blinds cloud |
| `thinq2-ha` | LG ThinQ AC |
| `localtuya` | Vivax AC (Path A — Tuya) |
| `smartir` | Vivax AC (Path B — IR fallback) |

### Required HACS frontend cards

Install via HACS → Frontend:

| Card | Repository |
|------|-----------|
| Mushroom Cards | `piitaya/lovelace-mushroom` |
| Button Card | `custom-cards/button-card` |
| Mini Graph Card | `kalkih/mini-graph-card` |
| Simple Thermostat | `nervetattoo/simple-thermostat` |
| Bubble Card | `Clooos/Bubble-Card` |
| Lovelace Swipe Navigation | `maykar/lovelace-swipe-navigation` |
| Mushroom Themes | (search in HACS Themes) |

Restart HA after installing all cards, then hard-refresh the browser (`Ctrl+Shift+R`).

---

## Integration Setup

### Philips Hue (built-in, local)
Settings → Devices & Services → Add Integration → Philips Hue → press button on Hue Bridge.

### IKEA DIRIGERA (built-in, local)
Settings → Add Integration → IKEA → press button on DIRIGERA hub.

### Govee LAN (HACS)
1. Enable LAN Control in the Govee Home app for each device (device settings → LAN Control)
2. Settings → Add Integration → Govee LAN

### VELUX (HACS)
Settings → Add Integration → VELUX → log in with your VELUX account.

### Samsung SmartThings (built-in)
1. Get a Personal Access Token at https://account.smartthings.com/tokens
2. Settings → Add Integration → SmartThings → enter token

### LG ThinQ (HACS — `thinq2-ha`)
Settings → Add Integration → LG ThinQ → log in with your LG ThinQ credentials.

### Vivax AC — Path A: LocalTuya (preferred)
1. Check if Vivax is Tuya-based: `pip install tinytuya && python -m tinytuya scan`
2. If found: get Device ID + Local Key from https://iot.tuya.com
3. Settings → Add Integration → LocalTuya → add device and map DPs:
   - DP 1: on/off · DP 2: target temp · DP 3: current temp · DP 4: mode · DP 5: fan speed

### Vivax AC — Path B: SmartIR + Broadlink (fallback)
If Vivax is not Tuya-based:
1. Add Broadlink RM4 Pro to HA (auto-discovered via Broadlink integration)
2. Download Vivax IR codes from https://github.com/smartHomeHub/SmartIR/tree/master/codes/climate
3. Copy JSON file to `config/codes/climate/`
4. In `config/configuration.yaml`, uncomment the `smartir:` and `climate:` lines
5. Edit `config/integrations/vivax_smartir_climate.yaml` with your device_code and controller entity

### Google Home (manual OAuth)
1. Create a Google Cloud project at https://console.cloud.google.com
2. Enable the HomeGraph API
3. Create a Service Account and download the JSON key to `config/google_credentials.json`
4. Create an Actions on Google project (Smart Home type) at https://console.actions.google.com
5. Set Fulfillment URL: `https://yourdomain.com/api/google_assistant`
6. Configure Account Linking with OAuth Client ID/Secret and HA auth/token URLs
7. Update `config/secrets.yaml` with your `google_project_id`, `google_oauth_client_id`, `google_oauth_client_secret`
8. Link in Google Home app: Add device → Works with Google → search your project

### Konfortvent
Already integrated and working — no setup needed. Update the entity IDs in:
- `config/automations/ventilation.yaml`
- `config/lovelace/views/04_ventilation.yaml`

---

## Dashboard Setup

1. In HA: Settings → Dashboards → Add Dashboard → name it `Home`
2. Open dashboard → ⋮ → Edit Dashboard → ⋮ → Raw configuration editor
3. Copy the contents of `config/lovelace/ui-lovelace.yaml` and paste it
4. **Replace all placeholder entity IDs** — search for `# replace` in the view files

### Create required helpers

Settings → Devices & Services → Helpers:
- Toggle: `input_boolean.vacation_mode`
- Light Group: `light.all_lights` (add all your light entities)
- Light Group: `light.living_room`, `light.bedroom`, `light.kitchen`

### Create scenes

Settings → Automations & Scenes → Scenes → Add Scene (or import `config/scenes/scenes.yaml` contents via YAML editor).

---

## Adding or Removing Integrations

The setup is modular. To add or remove an integration:

**Remove an integration:**
1. Set `enabled: false` in `settings.yaml` (documents intent)
2. Delete or rename the corresponding file in `config/integrations/`
3. Remove the `!include` reference in `config/configuration.yaml`
4. Restart HA

**Add a new integration:**
1. Create a new file in `config/integrations/your_integration.yaml`
2. Add an `!include integrations/your_integration.yaml` line in `config/configuration.yaml`
3. Add a new entry in `settings.yaml` under `integrations:`
4. Restart HA

**Remove an automation category:**
Simply delete the file from `config/automations/`. HA picks up all files via `!include_dir_list`.

**Remove a dashboard view:**
Delete the view file from `config/lovelace/views/` and remove its `!include` line from `config/lovelace/ui-lovelace.yaml`.

---

## Entity ID Reference

After setting up all integrations, replace these placeholder entity IDs in the config files:

| Placeholder | Where to find real ID |
|------------|----------------------|
| `cover.velux_*` | Settings → Developer Tools → States → filter "cover" |
| `climate.samsung_ac` | States → filter "climate" |
| `climate.lg_ac` | States → filter "climate" |
| `climate.vivax_ac` | States → filter "climate" |
| `fan.konfortvent` | States → filter "konfortvent" |
| `select.konfortvent_mode` | States → filter "konfortvent" |
| `sensor.konfortvent_*` | States → filter "konfortvent" |
| `light.living_room` | States → filter "light" |
| `binary_sensor.hue_motion_*` | States → filter "hue_motion" |
| `sensor.outdoor_temperature` | States → filter your outdoor sensor |
| `person.resident_1` | Settings → People |

---

## Keeping HA Updated

```bash
ssh admin@<QNAP-IP>
cd /share/homeassistant
docker compose pull
docker compose up -d
```

---

## Troubleshooting

**HA not accessible on LAN:**
- Verify `network_mode: host` is set in `docker-compose.yml`
- Check port 8123 is not blocked by QNAP firewall

**Hue / IKEA / Govee devices not discovered:**
- Must be on the same LAN subnet as the QNAP
- `network_mode: host` is required — bridge mode will break mDNS discovery

**Google Home not working:**
- Verify HTTPS endpoint is reachable from the internet: `curl https://yourdomain.com/api/`
- Check `config/google_credentials.json` exists and is the correct service account key
- In HA logs: filter by `google_assistant` to see errors

**LG ThinQ login fails:**
- Try changing the region to the country where your LG account was registered
- Some regions require a specific server URL — check the `thinq2-ha` HACS repo issues

**Vivax AC not responding (LocalTuya):**
- Re-run `python -m tinytuya scan` to confirm device is on LAN
- Local Key may have rotated — re-fetch from iot.tuya.com
- Fall back to SmartIR (Path B)
