#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../charts/helpers.sh
source "$(dirname "$0")/../charts/helpers.sh"

echo "=== GitHub admin auth config tests ==="

backend_index=$(cat backstage/packages/backend/src/index.ts)
app_config=$(cat backstage/app-config.yaml)
rbac_policies=$(cat backstage/rbac-policies.csv)

assert_contains "GitHub auth backend module is registered" "$backend_index" "backend.add(import('@backstage/plugin-auth-backend-module-github-provider'))"
assert_contains "GitHub auth provider is declared" "$app_config" "github:"
assert_contains "GitHub username resolver is configured" "$app_config" "resolver: usernameMatchingUserEntityName"
assert_not_contains "Base app config does not contain GitHub client ID" "$app_config" "clientId:"
assert_not_contains "Base app config does not contain GitHub client secret" "$app_config" "clientSecret:"
assert_not_contains "Base app config does not contain bootstrap admin users" "$app_config" "admin:"

tracked_files=$(git ls-files --cached --others --exclude-standard)
assert_contains "users.yaml is tracked" "$tracked_files" "users.yaml"
assert_contains "local config example is tracked" "$tracked_files" "backstage/app-config.local.example.yaml"
assert_not_contains "real local config is not tracked" "$tracked_files" "backstage/app-config.local.yaml"

users_yaml=$(cat users.yaml 2>/dev/null || true)
assert_contains "admin user entity is named itamar-ratson" "$users_yaml" "name: itamar-ratson"
assert_contains "admin user display name is configured" "$users_yaml" "displayName: Itamar Ratson"
assert_contains "admin user has empty group membership" "$users_yaml" "memberOf: []"

local_example=$(cat backstage/app-config.local.example.yaml 2>/dev/null || true)
assert_contains "local example includes GitHub client ID" "$local_example" "clientId: github-oauth-client-id"
assert_contains "local example includes GitHub client secret" "$local_example" "clientSecret: github-oauth-client-secret"
assert_contains "local example includes RBAC admin users" "$local_example" "permission:"
assert_contains "local example points at users.yaml" "$local_example" "target: ../../users.yaml"

assert_contains "platform-admin wildcard policy is present" "$rbac_policies" "p, role:default/platform-admin, *, *, allow"
assert_contains "admin user is assigned platform-admin" "$rbac_policies" "g, user:default/itamar-ratson, role:default/platform-admin"

report_results "GitHub admin auth config"
