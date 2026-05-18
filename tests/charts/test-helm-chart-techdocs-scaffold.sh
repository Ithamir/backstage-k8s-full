#!/usr/bin/env bash
set -euo pipefail

source tests/charts/helpers.sh

SKELETON_DIR="templates/helm-chart/skeleton"

echo "=== Helm chart TechDocs scaffold tests ==="

assert_contains "mkdocs scaffold inherits shared base" "$(cat "$SKELETON_DIR/mkdocs.yaml.njk" 2>/dev/null || true)" "INHERIT: ../../shared-mkdocs-base.yml"
assert_contains "mkdocs scaffold uses chart name" "$(cat "$SKELETON_DIR/mkdocs.yaml.njk" 2>/dev/null || true)" 'site_name: '\''${{ values.name }}'\'''
assert_contains "mkdocs scaffold sets docs dir" "$(cat "$SKELETON_DIR/mkdocs.yaml.njk" 2>/dev/null || true)" "docs_dir: docs"
assert_contains "mkdocs scaffold has explicit nav" "$(cat "$SKELETON_DIR/mkdocs.yaml.njk" 2>/dev/null || true)" "nav: [Home: index.md]"

assert_contains "docs index has chart title" "$(cat "$SKELETON_DIR/docs/index.md.njk" 2>/dev/null || true)" '# ${{ values.name }}'
assert_contains "docs index includes chart description" "$(cat "$SKELETON_DIR/docs/index.md.njk" 2>/dev/null || true)" '${{ values.description }}'
assert_contains "docs index has single TODO callout" "$(cat "$SKELETON_DIR/docs/index.md.njk" 2>/dev/null || true)" "> TODO: Describe what this chart does, its inputs, and how to operate it."

todo_count="$(grep -cF "TODO:" "$SKELETON_DIR/docs/index.md.njk" 2>/dev/null || echo 0)"
if [ "$todo_count" -eq 1 ]; then
  PASS=$((PASS + 1))
else
  FAIL=$((FAIL + 1))
  echo "FAIL: docs index has exactly one TODO callout"
  echo "  expected TODO count: 1"
  echo "  got: $todo_count"
fi

catalog_template="$(cat "$SKELETON_DIR/catalog-info.yaml.njk")"
assert_contains "catalog scaffold has techdocs annotation" "$catalog_template" "backstage.io/techdocs-ref: dir:."

report_results "Helm chart TechDocs scaffold"
