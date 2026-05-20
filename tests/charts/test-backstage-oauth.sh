#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=helpers.sh
source "$(dirname "$0")/helpers.sh"

echo "=== Backstage GitHub OAuth chart tests ==="

dev_values_args=(
  -f deploy/dev/backstage.yaml
  --set-file rbac.policies=backstage/rbac-policies.csv
  --set-file rbac.users=users.yaml
)

dev_output=$(helm template backstage "$CHART_DIR" \
  "${dev_values_args[@]}" 2>&1)

assert_contains "Deployment refs OAuth existingSecret" "$dev_output" "name: backstage-github-oauth"
assert_not_contains "OAuth Secret not rendered by dev default" "$dev_output" "AUTH_GITHUB_CLIENT_ID:"
assert_contains "ConfigMap has runtime config" "$dev_output" "app-config.runtime.yaml:"
assert_contains "ConfigMap has RBAC policies key" "$dev_output" "rbac-policies.csv:"
assert_contains "ConfigMap has users key" "$dev_output" "users.yaml:"
assert_contains "Runtime config has OAuth client ID placeholder" "$dev_output" 'clientId: ${AUTH_GITHUB_CLIENT_ID}'
assert_contains "Runtime config has OAuth client secret placeholder" "$dev_output" 'clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}'
assert_contains "Runtime config has RBAC admin user" "$dev_output" "user:default/itamar-ratson"
assert_contains "Runtime config has absolute RBAC CSV path" "$dev_output" "policies-csv-file: /etc/backstage/rbac-policies.csv"
assert_contains "Runtime config targets mounted users catalog" "$dev_output" "target: /etc/backstage/users.yaml"
assert_contains "ConfigMap remains mounted at /etc/backstage" "$dev_output" "mountPath: /etc/backstage"
assert_contains "ConfigMap volume mount remains read only" "$dev_output" "readOnly: true"

create_output=$(helm template backstage "$CHART_DIR" \
  "${dev_values_args[@]}" \
  --set oauth.github.create=true \
  --set oauth.github.clientId=ID \
  --set oauth.github.clientSecret=SECRET 2>&1)

assert_contains "OAuth create=true renders Secret" "$create_output" "name: backstage-github-oauth"
assert_contains "OAuth Secret has client ID key" "$create_output" "AUTH_GITHUB_CLIENT_ID:"
assert_contains "OAuth Secret has client secret key" "$create_output" "AUTH_GITHUB_CLIENT_SECRET:"

report_results "Backstage GitHub OAuth chart"
