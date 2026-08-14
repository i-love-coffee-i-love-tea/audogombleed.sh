#!/usr/bin/env bash
# release.d hook: stamp version in packaging/rpm/derakht-cli.spec.
# Uses $version for Version and $rebuild for Release (defaults to 1).
#
# Exports from release.sh: $version $rebuild
#
set -euo pipefail

file="packaging/rpm/derakht-cli.spec"
release="${rebuild:-1}"
sed -i "s/^Version:.*/Version:        $version/" "$file"
sed -i "s/^Release:.*/Release:        $release%{?dist}/" "$file"
echo "Stamped Version=$version Release=$release in $file"
