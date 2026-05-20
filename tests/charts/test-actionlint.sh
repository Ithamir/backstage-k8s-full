#!/usr/bin/env bash
set -euo pipefail

if ! command -v actionlint >/dev/null 2>&1; then
  echo "ERROR: actionlint is required to lint GitHub Actions workflows." >&2
  echo "Install actionlint and re-run this test." >&2
  exit 1
fi

mapfile -t workflows < <(find .github/workflows -type f \( -name '*.yaml' -o -name '*.yml' \) | sort)

if [ "${#workflows[@]}" -eq 0 ]; then
  echo "ERROR: no GitHub Actions workflow files found under .github/workflows." >&2
  exit 1
fi

actionlint "${workflows[@]}"
