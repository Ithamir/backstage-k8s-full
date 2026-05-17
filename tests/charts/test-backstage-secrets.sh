#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=helpers.sh
source "$(dirname "$0")/helpers.sh"

echo "=== GitHub auth hybrid tests ==="

# Test 1: create=true with token renders Secret and Deployment references it
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/github-create-true.yaml" 2>&1)
assert_contains "github create=true renders Secret" "$output" "name: backstage-github"
assert_contains "github Secret has GITHUB_TOKEN" "$output" "GITHUB_TOKEN:"
assert_contains "deployment refs github secret" "$output" "name: backstage-github"

# Test 2: create=false with existingSecret — no GitHub Secret rendered, Deployment references supplied name
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/github-existing-secret.yaml" 2>&1)
assert_contains "deployment refs existingSecret" "$output" "name: my-gh-secret"
assert_not_contains "github create=false should not render backstage-github Secret" "$output" "name: backstage-github"

# Test 3: create=true with empty token fails with required message
assert_fails "github empty token fails" "github.auth.token is required" \
  helm template backstage "$CHART_DIR" -f "$FIXTURES/github-create-empty-token.yaml"

echo ""
echo "=== Postgres auth hybrid tests ==="

# Test 4: create=true renders postgres Secret, both deployments reference it
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/postgres-create-true.yaml" 2>&1)
assert_contains "postgres create=true renders Secret" "$output" "name: backstage-postgres"
assert_contains "postgres Secret has POSTGRES_USER" "$output" "POSTGRES_USER:"
assert_contains "postgres Secret has POSTGRES_PASSWORD" "$output" "POSTGRES_PASSWORD:"
assert_contains "postgres Secret has POSTGRES_HOST" "$output" "POSTGRES_HOST:"

# Test 5: create=false with existingSecret — no postgres Secret rendered, Deployment references supplied name
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/postgres-existing-secret.yaml" 2>&1)
assert_contains "backstage deployment refs pg existingSecret" "$output" "name: my-pg-secret"
assert_not_contains "postgres create=false should not render postgres Secret data keys" "$output" "POSTGRES_USER:"

# Test 6: create=true with empty password fails with required message
assert_fails "postgres empty password fails" "postgres.auth.password is required" \
  helm template backstage "$CHART_DIR" -f "$FIXTURES/postgres-create-empty-password.yaml"

echo ""
echo "=== Postgres toggle tests ==="

# Test 7: postgres.enabled=true renders Deployment, Service, PVC
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/postgres-create-true.yaml" 2>&1)
deploy_count=$(echo "$output" | grep -c "kind: Deployment" || true)
assert_contains "postgres enabled has 2 Deployments" "count:$deploy_count" "count:2"
assert_contains "postgres Service present" "$output" "name: postgres"
assert_contains "postgres PVC present" "$output" "kind: PersistentVolumeClaim"

# Test 8: postgres.enabled=false — no postgres Deployment, Service, PVC, or Secret
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/postgres-disabled.yaml" 2>&1)
deploy_count=$(echo "$output" | grep -c "kind: Deployment" || true)
assert_contains "postgres disabled has 1 Deployment" "count:$deploy_count" "count:1"
assert_not_contains "no PVC when postgres disabled" "$output" "kind: PersistentVolumeClaim"
assert_not_contains "no postgres Secret when disabled" "$output" "POSTGRES_USER:"
assert_contains "backstage refs external pg secret" "$output" "name: external-pg-secret"

report_results "Secrets/postgres"
