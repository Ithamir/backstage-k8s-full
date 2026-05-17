#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=helpers.sh
source "$(dirname "$0")/helpers.sh"

# Test 1: default values use Chart.AppVersion as tag
output=$(helm template backstage "$CHART_DIR" --set github.auth.token=t --set postgres.auth.password=p 2>&1)
assert_contains "default tag uses appVersion" "$output" "image: \"backstage:1.0.0\""

# Test 2: explicit tag overrides appVersion
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/image-explicit-tag.yaml" --set github.auth.token=t --set postgres.auth.password=p 2>&1)
assert_contains "explicit tag overrides" "$output" "image: \"my-registry/backstage:2.5.0\""

# Test 3: pullSecrets renders imagePullSecrets
output=$(helm template backstage "$CHART_DIR" -f "$FIXTURES/image-pullsecrets.yaml" --set github.auth.token=t --set postgres.auth.password=p 2>&1)
assert_contains "pullSecrets renders" "$output" "imagePullSecrets"
assert_contains "pullSecrets name" "$output" "name: my-registry-cred"

# Test 4: no pullSecrets when empty
output=$(helm template backstage "$CHART_DIR" --set github.auth.token=t --set postgres.auth.password=p 2>&1)
assert_not_contains "no imagePullSecrets by default" "$output" "imagePullSecrets"

echo ""
echo "Image tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
