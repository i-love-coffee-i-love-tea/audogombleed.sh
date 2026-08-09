#!/usr/bin/env bash
# release.d hook: validate that config files exist and have expected structure.
#
# Exports from release.sh: $version $script $manpage $changelog
#
set -euo pipefail

if ! grep -q "^__CLI_VERSION=" "$script"; then
    echo "error: __CLI_VERSION not found in $script"
    exit 1
fi

if ! grep -q '^\.TH ' "$manpage"; then
    echo "error: .TH header not found in $manpage"
    exit 1
fi

if [ ! -f "$changelog" ]; then
    echo "error: $changelog not found"
    exit 1
fi
