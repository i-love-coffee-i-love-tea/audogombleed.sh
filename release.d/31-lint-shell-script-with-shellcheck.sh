#!/usr/bin/env bash
# release.d hook: lint derakht.sh with shellcheck.
#
# Exports from release.sh: $script
# Skips gracefully if shellcheck is not installed.
#
set -euo pipefail

if ! command -v shellcheck &>/dev/null; then
    echo "warning: shellcheck not found, skipping lint"
    exit 0
fi

echo "Linting $script with shellcheck..."
shellcheck --shell=bash "$script"
echo "shellcheck passed."
