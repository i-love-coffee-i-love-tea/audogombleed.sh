#!/usr/bin/env bash
# release.d hook: stamp $version in packaging/rpm/audogombleed.spec.
#
# Exports from release.sh: $version
#
set -euo pipefail

file="packaging/rpm/audogombleed.spec"
sed -i "s/^Version:.*/Version:        $version/" "$file"
echo "Stamped $version in $file"
