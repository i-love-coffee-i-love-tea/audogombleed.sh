#!/usr/bin/env bash
# release.d hook: stamp version in packaging/homebrew/derakht-cli.rb.
# Uses $version for the tarball URL (git tag) and $full_version for the formula version.
#
# Exports from release.sh: $version $full_version
#
set -euo pipefail

file="packaging/homebrew/derakht-cli.rb"
sed -i "s|/archive/refs/tags/v[0-9.]*\.tar\.gz|/archive/refs/tags/v${version}.tar.gz|" "$file"
# Homebrew version field: use full_version (e.g. "2.0.0+1"), fall back to version if no rebuild
homebrew_version="${full_version:-$version}"
sed -i "s/^  version \"[^\"]*\"/  version \"$homebrew_version\"/" "$file" 2>/dev/null || true
echo "Stamped version=$homebrew_version url_tag=v$version in $file"
