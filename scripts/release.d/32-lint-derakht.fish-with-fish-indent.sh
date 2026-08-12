#!/usr/bin/env bash
# release.d hook: lint derakht.fish with fish_indent.
#
# Skips gracefully if fish is not installed.
#
set -euo pipefail

fish_script="derakht.fish"

if ! command -v fish &>/dev/null; then
    echo "warning: fish not found, skipping lint"
    exit 0
fi

echo "Linting $fish_script with fish_indent..."
fish --command "fish_indent --check $fish_script"
echo "fish_indent passed."
