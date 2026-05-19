#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=helpers.sh
source "$(dirname "$0")/helpers.sh"

echo "=== Backstage GitHub OAuth chart tests ==="

kind_values_args=(
  -f deploy/kind/backstage.yaml
  --set-file rbac.policies=backstage/rbac-policies.csv
  --set-file rbac.users=users.yaml
)

kind_output=$(helm template backstage "$CHART_DIR" \
  "${kind_values_args[@]}" 2>&1)

assert_contains "Deployment refs OAuth existingSecret" "$kind_output" "name: backstage-github-oauth"
assert_not_contains "OAuth Secret not rendered by kind default" "$kind_output" "AUTH_GITHUB_CLIENT_ID:"
assert_contains "ConfigMap has runtime config" "$kind_output" "app-config.runtime.yaml:"
assert_contains "ConfigMap has RBAC policies key" "$kind_output" "rbac-policies.csv:"
assert_contains "ConfigMap has users key" "$kind_output" "users.yaml:"
assert_contains "Runtime config has OAuth client ID placeholder" "$kind_output" 'clientId: ${AUTH_GITHUB_CLIENT_ID}'
assert_contains "Runtime config has OAuth client secret placeholder" "$kind_output" 'clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}'
assert_contains "Runtime config has RBAC admin user" "$kind_output" "user:default/itamar-ratson"
assert_contains "Runtime config has absolute RBAC CSV path" "$kind_output" "policies-csv-file: /etc/backstage/rbac-policies.csv"
assert_contains "Runtime config targets mounted users catalog" "$kind_output" "target: /etc/backstage/users.yaml"
assert_contains "ConfigMap remains mounted at /etc/backstage" "$kind_output" "mountPath: /etc/backstage"
assert_contains "ConfigMap volume mount remains read only" "$kind_output" "readOnly: true"

create_output=$(helm template backstage "$CHART_DIR" \
  "${kind_values_args[@]}" \
  --set oauth.github.create=true \
  --set oauth.github.clientId=ID \
  --set oauth.github.clientSecret=SECRET 2>&1)

assert_contains "OAuth create=true renders Secret" "$create_output" "name: backstage-github-oauth"
assert_contains "OAuth Secret has client ID key" "$create_output" "AUTH_GITHUB_CLIENT_ID:"
assert_contains "OAuth Secret has client secret key" "$create_output" "AUTH_GITHUB_CLIENT_SECRET:"

report_results "Backstage GitHub OAuth chart"
