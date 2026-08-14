#!/usr/bin/env bash
# release.d hook: stamp version in packaging/nix/derakht.nix.
# Uses $full_version for the package version and $version for the git tag rev.
#
# Exports from release.sh: $version $full_version
#
set -euo pipefail

file="packaging/nix/derakht.nix"
sed -i "s/version = \"[^\"]*\"/version = \"$full_version\"/" "$file"
sed -i "s/rev = \"v[^\"]*\"/rev = \"v$version\"/" "$file"
echo "Stamped version=$full_version rev=v$version in $file"
