#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "usage: $0 <version>"
    echo "  e.g. $0 1.2.0"
    exit 1
fi

version="$1"
script="audogombleed.sh"

if ! grep -q "^__CLI_VERSION=" "$script"; then
    echo "error: __CLI_VERSION not found in $script"
    exit 1
fi

sed -i "s/^__CLI_VERSION=.*/__CLI_VERSION=\"$version\"/" "$script"

git add "$script"
git commit -m "Bump version to $version"
git tag "v$version"

echo "Tagged v$version — run 'git push && git push --tags' to publish"
