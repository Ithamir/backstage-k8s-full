#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=helpers.sh
source "$(dirname "$0")/helpers.sh"

echo "=== Backstage mkdocs image toolchain tests ==="

dockerfile=$(cat backstage/Dockerfile)
dockerignore=$(cat backstage/.dockerignore)

assert_contains "final image installs python3-pip" "$dockerfile" "python3-pip"
assert_contains "techdocs core is pinned" "$dockerfile" "mkdocs-techdocs-core==1.6.2"
assert_contains "mermaid plugin is pinned" "$dockerfile" "mkdocs-mermaid2-plugin==1.2.3"
assert_contains "pip bypasses externally managed marker" "$dockerfile" "--break-system-packages"
assert_contains "dockerignore excludes docs" "$dockerignore" "docs/"

report_results "Backstage mkdocs image toolchain"
