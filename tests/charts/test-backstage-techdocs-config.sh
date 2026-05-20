#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=helpers.sh
source "$(dirname "$0")/helpers.sh"

echo "=== TechDocs runtime config tests ==="

output=$(helm template backstage "$CHART_DIR" -f deploy/dev/backstage.yaml 2>&1)

assert_contains "ConfigMap has techdocs block" "$output" "techdocs:"
assert_contains "TechDocs builder runs locally" "$output" "builder: local"
assert_contains "TechDocs generator runs locally" "$output" "runIn: local"
assert_contains "TechDocs publisher is local" "$output" "type: local"

report_results "TechDocs runtime config"
