#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../charts/helpers.sh
source "$(dirname "$0")/../charts/helpers.sh"

echo "=== GitHub admin auth config tests ==="

backend_index_path="backstage/packages/backend/src/index.ts"
app_config_path="backstage/app-config.yaml"
local_config_example_path="backstage/app-config.local.example.yaml"
local_config_path="backstage/app-config.local.yaml"
rbac_policies_path="backstage/rbac-policies.csv"
users_path="users.yaml"
sign_in_module_path="backstage/packages/app/src/modules/signIn/index.tsx"
app_path="backstage/packages/app/src/App.tsx"

backend_index=$(cat "$backend_index_path")
app_config=$(cat "$app_config_path")
rbac_policies=$(cat "$rbac_policies_path")
sign_in_module=$(cat "$sign_in_module_path" 2>/dev/null || true)
app_tsx=$(cat "$app_path")

assert_contains "GitHub auth backend module is registered" "$backend_index" "backend.add(import('@backstage/plugin-auth-backend-module-github-provider'))"
assert_contains "GitHub auth provider is declared" "$app_config" "github:"
assert_contains "GitHub username resolver is configured" "$app_config" "resolver: usernameMatchingUserEntityName"
assert_not_contains "Base app config does not contain GitHub client ID" "$app_config" "clientId:"
assert_not_contains "Base app config does not contain GitHub client secret" "$app_config" "clientSecret:"
assert_not_contains "Base app config does not contain bootstrap admin users" "$app_config" "admin:"

tracked_files=$(git ls-files --cached)
repo_visible_files=$(git ls-files --cached --others --exclude-standard)

assert_contains "users.yaml is tracked" "$tracked_files" "$users_path"
assert_contains "local config example is tracked" "$tracked_files" "$local_config_example_path"
assert_not_contains "real local config is not tracked or unignored" "$repo_visible_files" "$local_config_path"

users_yaml=$(cat "$users_path" 2>/dev/null || true)
assert_contains "admin user entity is named itamar-ratson" "$users_yaml" "name: itamar-ratson"
assert_contains "admin user display name is configured" "$users_yaml" "displayName: Itamar Ratson"
assert_contains "admin user has empty group membership" "$users_yaml" "memberOf: []"

local_example=$(cat "$local_config_example_path" 2>/dev/null || true)
assert_contains "local example includes GitHub client ID" "$local_example" "clientId: github-oauth-client-id"
assert_contains "local example includes GitHub client secret" "$local_example" "clientSecret: github-oauth-client-secret"
assert_contains "local example includes RBAC admin users" "$local_example" "permission:"
assert_contains "local example points at users.yaml" "$local_example" "target: ../../users.yaml"

assert_contains "platform-admin wildcard policy is present" "$rbac_policies" "p, role:default/platform-admin, *, *, allow"
assert_contains "admin user is assigned platform-admin" "$rbac_policies" "g, user:default/itamar-ratson, role:default/platform-admin"

assert_contains "sign-in module exports signInModule" "$sign_in_module" "export const signInModule"
assert_contains "sign-in module uses SignInPageBlueprint" "$sign_in_module" "SignInPageBlueprint"
assert_contains "sign-in module uses GitHub auth api ref" "$sign_in_module" "githubAuthApiRef"
assert_contains "sign-in module keeps guest provider" "$sign_in_module" "'guest'"
assert_contains "sign-in module declares GitHub provider id" "$sign_in_module" "'github-auth-provider'"
assert_contains "App imports signInModule" "$app_tsx" "import { signInModule } from './modules/signIn';"
assert_contains "App registers signInModule in features" "$app_tsx" "features: [catalogPlugin, kubernetesPlugin, rbacPlugin, navModule, signInModule]"

report_results "GitHub admin auth config"
