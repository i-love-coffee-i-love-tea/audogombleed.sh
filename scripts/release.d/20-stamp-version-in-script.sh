#!/usr/bin/env bash
# release.d hook: stamp $full_version into derakht.sh (__CLI_VERSION).
#
# Exports from release.sh: $full_version $script
#
set -euo pipefail

sed -i "s/^__CLI_VERSION=.*/__CLI_VERSION=\"$full_version\"/" "$script"
echo "Stamped $full_version in $script"
