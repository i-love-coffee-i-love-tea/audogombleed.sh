#!/usr/bin/env bash
# release.d hook: stamp $version in packaging/nix/default.nix.
#
# Exports from release.sh: $version
#
set -euo pipefail

file="packaging/nix/default.nix"
sed -i "s/version = \"[^\"]*\"/version = \"$version\"/" "$file"
echo "Stamped $version in $file"
