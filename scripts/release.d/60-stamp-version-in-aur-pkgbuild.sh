#!/usr/bin/env bash
# release.d hook: stamp $version in packaging/arch/PKGBUILD.
#
# Exports from release.sh: $version
#
set -euo pipefail

file="packaging/arch/PKGBUILD"
sed -i "s/^pkgver=.*/pkgver=$version/" "$file"
echo "Stamped $version in $file"
