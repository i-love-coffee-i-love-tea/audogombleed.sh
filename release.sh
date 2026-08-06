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

if ! grep -q "^__CLI_VERSION=" "$script"; then
    echo "error: __CLI_VERSION not found in $script"
    exit 1
fi

if ! grep -q '^\.TH ' "$manpage"; then
    echo "error: .TH header not found in $manpage"
    exit 1
fi

sed -i "s/^__CLI_VERSION=.*/__CLI_VERSION=\"$version\"/" "$script"
sed -i "s/^\(\.TH [^ ]\+ [0-9]\+ \)\"[^\"]*\" \"[^\"]*\"/\1\"$(date +%Y)\" \"$version\"/" "$manpage"

git add "$script" "$manpage"
git commit -m "Bump version to $version"
git tag "v$version"

echo "Tagged v$version — run 'git push && git push --tags' to publish"
