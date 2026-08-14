#!/usr/bin/env bash
# release.d hook: stamp $full_version and current year into the manpage (.TH header).
#
# Exports from release.sh: $full_version $manpage
#
set -euo pipefail

sed -i "s/^\(\.TH [^ ]\+ [0-9]\+ \)\"[^\"]*\" \"[^\"]*\"/\1\"$(date +%Y)\" \"$full_version\"/" "$manpage"
echo "Stamped $full_version in $manpage"
