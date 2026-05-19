#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../charts/helpers.sh
source "$(dirname "$0")/../charts/helpers.sh"

policy_file="${RBAC_POLICIES_CSV:-backstage/rbac-policies.csv}"
policy_csv=$(cat "$policy_file")

echo "=== RBAC policies CSV tests ==="

assert_contains "viewer can read catalog entities" "$policy_csv" "p, role:default/viewer, catalog-entity, read, allow"
assert_contains "viewer can read scaffolder templates" "$policy_csv" "p, role:default/viewer, scaffolder-template, read, allow"
assert_not_contains "viewer cannot execute scaffolder actions" "$policy_csv" "p, role:default/viewer, scaffolder-action, use, allow"
assert_contains "platform-admin has wildcard access" "$policy_csv" "p, role:default/platform-admin, *, *, allow"
assert_contains "guest is assigned viewer" "$policy_csv" "g, user:default/guest, role:default/viewer"
assert_contains "admin user is assigned platform-admin" "$policy_csv" "g, user:default/itamar-ratson, role:default/platform-admin"

report_results "RBAC policies CSV"
