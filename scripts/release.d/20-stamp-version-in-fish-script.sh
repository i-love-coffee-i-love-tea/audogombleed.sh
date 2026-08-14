#!/usr/bin/env bash
# release.d hook: stamp $full_version into derakht.fish (__CLI_VERSION).
#
# Exports from release.sh: $full_version
#
set -euo pipefail

fish_script="derakht.fish"

sed -i "s/^set -gx __CLI_VERSION .*/set -gx __CLI_VERSION \"$full_version\"/" "$fish_script"
echo "Stamped $full_version in $fish_script"
