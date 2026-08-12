#!/usr/bin/env bash
# release.d hook: validate release artifacts exist and have expected structure.
# Checks: __CLI_VERSION in script, .TH header in manpage, changelog file.
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
