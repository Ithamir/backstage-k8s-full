#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=helpers.sh
source tests/charts/helpers.sh

SKELETON_DIR="templates/ci-cd-pipeline/skeleton"
TEMPLATE="$(cat templates/ci-cd-pipeline/template.yaml)"
CALLER_TEMPLATE="$(cat "$SKELETON_DIR/.github/workflows/caller-\${{ values.name }}.yaml.njk")"
OVERLAY_TEMPLATE="$(cat "$SKELETON_DIR/deploy/dev/\${{ values.name }}.yaml.njk")"

echo "=== CI/CD pipeline scaffold tests ==="

assert_contains "template publishes a pull request" "$TEMPLATE" "publish:github:pull-request"
assert_contains "template documents Dockerfile prerequisite" "$TEMPLATE" "Requires a working Dockerfile"
assert_contains "template documents scaffold-created bump file" "$TEMPLATE" "bump file is created by this scaffold"
assert_not_contains "template does not catalog register" "$TEMPLATE" "catalog:register"
assert_not_contains "template does not catalog write" "$TEMPLATE" "catalog-info.yaml"

assert_contains "caller uses reusable build workflow" "$CALLER_TEMPLATE" "uses: ./.github/workflows/build-image.yaml"
assert_contains "caller emits app-name substitution" "$CALLER_TEMPLATE" 'app-name: ${{ values.name }}'
assert_contains "caller emits context substitution" "$CALLER_TEMPLATE" 'context: ${{ values.context }}'
assert_contains "caller emits dockerfile substitution" "$CALLER_TEMPLATE" 'dockerfile: ${{ values.dockerfile }}'
assert_contains "caller emits bump-file substitution" "$CALLER_TEMPLATE" "bump-file: \${{ values['bump-file'] }}"
assert_contains "caller emits bump-yaml-path substitution" "$CALLER_TEMPLATE" "bump-yaml-path: \${{ values['bump-yaml-path'] }}"
assert_contains "caller renders path filter patterns" "$CALLER_TEMPLATE" "path-filter-patterns"

assert_contains "overlay references GHCR app path" "$OVERLAY_TEMPLATE" 'repository: ghcr.io/itamar-ratson/backstage-k8s-full/${{ values.name }}'
assert_contains "overlay starts with empty tag" "$OVERLAY_TEMPLATE" 'tag: ""'
assert_contains "overlay uses IfNotPresent pull policy" "$OVERLAY_TEMPLATE" "pullPolicy: IfNotPresent"

report_results "CI/CD pipeline scaffold"
