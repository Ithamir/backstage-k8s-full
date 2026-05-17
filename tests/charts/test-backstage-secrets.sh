#!/usr/bin/env bash
set -euo pipefail

CHART_DIR="charts/backstage"
FIXTURES="tests/charts/fixtures"
PASS=0
FAIL=0

assert_contains() {
  local label="$1" output="$2" expected="$3"
  if echo "$output" | grep -qF "$expected"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label"
    echo "  expected to contain: $expected"
  fi
}

assert_not_contains() {
  local label="$1" output="$2" unexpected="$3"
  if ! echo "$output" | grep -qF "$unexpected"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label"
    echo "  expected NOT to contain: $unexpected"
  fi
}

assert_fails() {
  local label="$1" expected_msg="$2"
  shift 2
  local output
  if output=$("$@" 2>&1); then
    FAIL=$((FAIL + 1))
    echo "FAIL: $label (expected failure but succeeded)"
  elif echo "$output" | grep -qF "$expected_msg"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label"
    echo "  expected error containing: $expected_msg"
    echo "  got: $output"
  fi
}

echo "=== GitHub auth hybrid tests ==="

# Test 1: create=true with token renders Secret and Deployment references it
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/github-create-true.yaml" 2>&1)
assert_contains "github create=true renders Secret" "$output" "name: backstage-github"
assert_contains "github Secret has GITHUB_TOKEN" "$output" "GITHUB_TOKEN:"
assert_contains "deployment refs github secret" "$output" "name: backstage-github"

# Test 2: create=false with existingSecret — no GitHub Secret rendered, Deployment references supplied name
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/github-existing-secret.yaml" 2>&1)
assert_contains "deployment refs existingSecret" "$output" "name: my-gh-secret"

# Verify the github Secret resource is truly absent
github_secret_count=$(echo "$output" | grep -c "name: backstage-github" || true)
if [ "$github_secret_count" -eq 0 ]; then
  PASS=$((PASS + 1))
else
  FAIL=$((FAIL + 1))
  echo "FAIL: github create=false should not render backstage-github Secret"
fi

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

postgres_secret_count=$(echo "$output" | grep -c "POSTGRES_USER:" || true)
if [ "$postgres_secret_count" -eq 0 ]; then
  PASS=$((PASS + 1))
else
  FAIL=$((FAIL + 1))
  echo "FAIL: postgres create=false should not render postgres Secret data keys"
fi

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

echo ""
echo "Secrets/postgres tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
