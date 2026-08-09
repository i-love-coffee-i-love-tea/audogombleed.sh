#!/usr/bin/env bash
# release.d hook: stamp $version into audogombleed.sh (__CLI_VERSION).
#
# Exports from release.sh: $version $script
#
set -euo pipefail

sed -i "s/^__CLI_VERSION=.*/__CLI_VERSION=\"$version\"/" "$script"
echo "Stamped $version in $script"
