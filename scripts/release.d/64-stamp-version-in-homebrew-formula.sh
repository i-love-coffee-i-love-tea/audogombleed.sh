#!/usr/bin/env bash
# release.d hook: stamp $version in packaging/homebrew/derakht-cli.rb.
#
# Exports from release.sh: $version
#
set -euo pipefail

file="packaging/homebrew/derakht-cli.rb"
sed -i "s|/archive/refs/tags/v[0-9.]*\.tar\.gz|/archive/refs/tags/v${version}.tar.gz|" "$file"
echo "Stamped $version in $file"
