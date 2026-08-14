#!/usr/bin/env bash
# release.d hook: stamp version in packaging/arch/PKGBUILD.
# Uses $version for pkgver and $rebuild for pkgrel (defaults to 1).
#
# Exports from release.sh: $version $rebuild
#
set -euo pipefail

file="packaging/arch/PKGBUILD"
pkgrel="${rebuild:-1}"
sed -i "s/^pkgver=.*/pkgver=$version/" "$file"
sed -i "s/^pkgrel=.*/pkgrel=$pkgrel/" "$file"
echo "Stamped pkgver=$version pkgrel=$pkgrel in $file"
