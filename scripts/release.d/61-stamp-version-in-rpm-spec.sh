#!/usr/bin/env bash
# release.d hook: stamp $version in packaging/rpm/derakht-cli.spec.
#
# Exports from release.sh: $version
#
set -euo pipefail

file="packaging/rpm/derakht-cli.spec"
sed -i "s/^Version:.*/Version:        $version/" "$file"
echo "Stamped $version in $file"
