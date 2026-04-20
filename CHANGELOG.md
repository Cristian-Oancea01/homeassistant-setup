# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses [Semantic Versioning](https://semver.org/).

---

## [1.0.0] — 2026-04-18

### Added
- Initial public release
- Modular Home Assistant configuration for QNAP NAS (Container Station)
- `docker-compose.yml` with host-network mode for local device discovery
- `.env.example` and `config/secrets.yaml.example` with all required variables documented
- `settings.yaml` integration and automation feature toggles
- `config/configuration.yaml` with modular `!include` structure
- **Integrations:** Philips Hue, Govee LAN, IKEA DIRIGERA, VELUX, Samsung SmartThings, LG ThinQ, Vivax AC (LocalTuya + SmartIR fallback), Google Home (manual OAuth), Komfovent HRV
- **Automations:** blinds (sunrise/sunset/heat), lighting (motion, welcome home), climate (AC schedule, window guard, good night), ventilation (away/return presence)
- **Scenes:** Morning, Evening, Movie, Night, Away
- **Scripts:** Good Night on-demand script
- **Lovelace dashboard:** 6 views — Home, Lighting, Climate, Ventilation, Blinds, Settings
- Mushroom Cards, Button Card, Mini Graph Card, Simple Thermostat support
- `scripts/deploy.sh` — rsync config to QNAP + container restart
- `scripts/validate.sh` — YAML syntax check before deploy
- Full README with Quick Start, HTTPS setup, HACS setup, integration guides, entity ID reference, troubleshooting
