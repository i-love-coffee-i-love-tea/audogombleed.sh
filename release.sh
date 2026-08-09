#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "usage: $0 <version>"
    echo "  e.g. $0 1.2.0"
    exit 1
fi

version="$1"
script="audogombleed.sh"
manpage="audogombleed.1"
changelog="debian/changelog"
hook_dir="release.d"

export version script manpage changelog

for hook in "$hook_dir"/*.sh; do
    [ -x "$hook" ] || continue
    echo "Running hook: $(basename "$hook")"
    "$hook"
done
