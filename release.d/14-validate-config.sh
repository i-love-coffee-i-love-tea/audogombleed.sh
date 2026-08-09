#!/usr/bin/env bash
# Validate an audogombleed config file against the formal grammar (ADR-011).
#
# Usage:
#   ./validate-config.sh <config-file>
#
# This is a convenience wrapper. The validator is embedded in audogombleed.sh
# and available to every derived CLI via --cli-validate-config.
#
# Exit 0 if valid, exit 1 if errors found.
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "usage: $0 <config-file>"
    exit 1
fi

config="$1"

if [ ! -f "$config" ]; then
    echo "error: config file '$config' not found"
    exit 1
fi

# Create a temporary symlink so the embedded script can determine its name.
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
ln -sf "$PWD/audogombleed.sh" "$tmpdir/validate"
"$tmpdir/validate" --cli-validate-config "$config"
