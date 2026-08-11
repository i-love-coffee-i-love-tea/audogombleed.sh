#!/usr/bin/env bash
# release.d hook: stamp $version into derakht.fish (__CLI_VERSION).
#
# Exports from release.sh: $version
#
set -euo pipefail

fish_script="derakht.fish"

sed -i "s/^set -gx __CLI_VERSION .*/set -gx __CLI_VERSION \"$version\"/" "$fish_script"
echo "Stamped $version in $fish_script"
