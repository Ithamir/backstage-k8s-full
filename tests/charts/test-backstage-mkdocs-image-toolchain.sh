#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=helpers.sh
source "$(dirname "$0")/helpers.sh"

echo "=== Backstage mkdocs image toolchain tests ==="

dockerignore=$(cat backstage/.dockerignore)
final_stage=$(awk '/^FROM node:22-bookworm-slim$/ { in_final_stage = 1; next } in_final_stage { print }' backstage/Dockerfile)

assert_contains "final image installs python3-pip" "$final_stage" "python3-pip"
assert_contains "techdocs core is pinned" "$final_stage" "mkdocs-techdocs-core==1.6.2"
assert_contains "mermaid plugin is pinned" "$final_stage" "mkdocs-mermaid2-plugin==1.2.3"
assert_contains "pip bypasses externally managed marker" "$final_stage" "--break-system-packages"
assert_contains "dockerignore excludes docs" "$dockerignore" "docs/"

report_results "Backstage mkdocs image toolchain"
