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

sed -i "s/^__CLI_VERSION=.*/__CLI_VERSION=\"$version\"/" "$script"
sed -i "s/^\(\.TH [^ ]\+ [0-9]\+ \)\"[^\"]*\" \"[^\"]*\"/\1\"$(date +%Y)\" \"$version\"/" "$manpage"

# Update debian/changelog: version in first line, date in maintainer line
rfc_date=$(date -R)
sed -i "1s/audogombleed ([^)]*)/audogombleed ($version)/" "$changelog"
sed -i "1s/\* Release .*/\* Release $version/" "$changelog"
sed -i "s/^ -- .*<.*>  .*$/ -- Steffen Kremsler <steffen@example.com>  $rfc_date/" "$changelog"

git add "$script" "$manpage" "$changelog"
git commit -m "Bump version to $version"
git tag "v$version"

echo "Tagged v$version — run 'git push && git push --tags' to publish"
