#!/usr/bin/env bash
# release.d hook: stamp __INSTALLED_PATH__ in the manpage.
#
# Replaces the placeholder with /usr/bin/derakht (the default installed path).
# Package-specific builds in CI can override with sed if needed
# (e.g. FreeBSD uses /usr/local/bin/derakht).
#
# Exports from release.sh: $manpage
#
set -euo pipefail

sed -i 's|__INSTALLED_PATH__|/usr/bin/derakht|g' "$manpage"
echo "Stamped installed path in $manpage"
