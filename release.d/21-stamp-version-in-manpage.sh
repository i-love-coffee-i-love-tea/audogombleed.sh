#!/usr/bin/env bash
# release.d hook: stamp $version and current year into the manpage (.TH header).
#
# Exports from release.sh: $version $manpage
#
set -euo pipefail

sed -i "s/^\(\.TH [^ ]\+ [0-9]\+ \)\"[^\"]*\" \"[^\"]*\"/\1\"$(date +%Y)\" \"$version\"/" "$manpage"
echo "Stamped $version in $manpage"
