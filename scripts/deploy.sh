#!/usr/bin/env bash
# scripts/deploy.sh
# ============================================================
# Deploy this Home Assistant config to your QNAP NAS.
#
# Usage:
#   ./scripts/deploy.sh [QNAP_IP] [QNAP_USER] [HA_CONFIG_PATH]
#
# Examples:
#   ./scripts/deploy.sh <qnap-ip> <qnap-user> /share/homeassistant/config
#   ./scripts/deploy.sh   (uses defaults from .env)
#
# What it does:
#   1. Reads .env for defaults
#   2. rsyncs config/ to the QNAP over SSH
#   3. Copies secrets.yaml (from config/secrets.yaml — NOT in git)
#   4. Restarts the homeassistant container
# ============================================================

set -euo pipefail

# ── Load .env if it exists ────────────────────────────────
if [ -f .env ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

QNAP_IP="${1:-${QNAP_IP:-REPLACE_ME}}"
QNAP_USER="${2:-${QNAP_USER:-REPLACE_ME}}"
HA_CONFIG_PATH="${3:-${HA_CONFIG_PATH:-/share/homeassistant/config}}"

echo "==> Deploying to ${QNAP_USER}@${QNAP_IP}:${HA_CONFIG_PATH}"

# ── Validate secrets.yaml exists locally ─────────────────
if [ ! -f "config/secrets.yaml" ]; then
  echo "ERROR: config/secrets.yaml not found."
  echo "       Copy config/secrets.yaml.example to config/secrets.yaml and fill in your values."
  exit 1
fi

# ── Sync config files ─────────────────────────────────────
rsync -avz --delete \
  --exclude='.git' \
  --exclude='custom_components/' \
  --exclude='*.pyc' \
  --exclude='.storage/' \
  --exclude='home-assistant.log' \
  config/ \
  "${QNAP_USER}@${QNAP_IP}:${HA_CONFIG_PATH}/"

echo "==> Config synced."

# ── Restart HA container ──────────────────────────────────
echo "==> Restarting Home Assistant container..."
ssh "${QNAP_USER}@${QNAP_IP}" "docker restart homeassistant"

echo ""
echo "✓ Deployment complete."
echo "  HA will be available at http://${QNAP_IP}:8123 in ~60 seconds."
