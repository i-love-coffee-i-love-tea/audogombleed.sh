#!/usr/bin/env bash
set -euo pipefail

# Build a .deb package for distribution.
#
# Usage:
#   ./build-deb.sh            # unsigned (for testing)
#   ./build-deb.sh --sign     # signed with GPG key
#
# The .deb is placed in the parent directory.
# Upload to GitHub Releases:
#   gh release create v1.3.0 ../audogombleed_1.3.0_all.deb

sign=false
if [ "${1:-}" = "--sign" ]; then
    sign=true
fi

version=$(grep '^__CLI_VERSION=' audogombleed.sh | cut -d'"' -f2)
if [ -z "$version" ]; then
    echo "error: could not read version from audogombleed.sh"
    exit 1
fi

echo "Building audogombleed ${version}..."

if $sign; then
    # Check for GPG key matching the maintainer email in debian/control
    maintainer=$(grep '^Maintainer:' debian/control | sed 's/.*<\(.*\)>.*/\1/')
    if ! gpg --list-keys "$maintainer" >/dev/null 2>&1; then
        echo "error: no GPG key found for $maintainer"
        echo "Generate one with: gpg --gen-key"
        exit 1
    fi
    dpkg-buildpackage -b 2>&1
else
    dpkg-buildpackage -us -uc -b 2>&1
fi

deb="../audogombleed_${version}_all.deb"
if [ ! -f "$deb" ]; then
    echo "error: .deb not found at $deb"
    exit 1
fi

echo
echo "Built: $deb"
ls -lh "$deb"

if $sign; then
    echo
    echo "Package is signed. Upload to GitHub Releases:"
    echo "  gh release create v${version} $deb"
else
    echo
    echo "Package is UNSIGNED. For distribution, re-run with --sign:"
    echo "  ./build-deb.sh --sign"
fi
