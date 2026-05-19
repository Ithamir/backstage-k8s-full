#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=helpers.sh
source tests/charts/helpers.sh

SKELETON_DIR="templates/helm-chart/skeleton"
HELPERS_TEMPLATE="$(cat "$SKELETON_DIR/templates/_helpers.tpl")"
CATALOG_TEMPLATE="$(cat "$SKELETON_DIR/catalog-info.yaml.njk")"

echo "=== Helm chart Kubernetes scaffold tests ==="

assert_contains "helpers scaffold emits kubernetes-id label" "$HELPERS_TEMPLATE" "backstage.io/kubernetes-id: {{ .Chart.Name }}"
assert_contains "catalog scaffold has kubernetes-id annotation" "$CATALOG_TEMPLATE" 'backstage.io/kubernetes-id: ${{ values.name }}'

report_results "Helm chart Kubernetes scaffold"
