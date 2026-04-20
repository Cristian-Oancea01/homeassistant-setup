#!/usr/bin/env bash
# scripts/validate.sh
# ============================================================
# Validate configuration files before deploying.
# Checks YAML syntax on all config files.
#
# Requirements: python3 with pyyaml installed
#   pip install pyyaml
# ============================================================

set -euo pipefail

ERRORS=0

check_yaml() {
  local file="$1"
  python3 -c "
import yaml, sys
try:
    with open('$file') as f:
        yaml.safe_load(f)
    print('  OK  $file')
except yaml.YAMLError as e:
    print('  FAIL $file')
    print('      ' + str(e))
    sys.exit(1)
" || ERRORS=$((ERRORS + 1))
}

echo "==> Validating YAML files..."

find config -name "*.yaml" | sort | while read -r f; do
  check_yaml "$f"
done

check_yaml "docker-compose.yml"
check_yaml "settings.yaml"

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "✓ All YAML files are valid."
else
  echo "✗ ${ERRORS} file(s) failed validation. Fix before deploying."
  exit 1
fi
