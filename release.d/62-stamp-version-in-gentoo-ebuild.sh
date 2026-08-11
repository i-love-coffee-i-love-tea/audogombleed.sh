#!/usr/bin/env bash
# release.d hook: stamp $version in the Gentoo ebuild (rename + update copyright year).
#
# Exports from release.sh: $version
#
set -euo pipefail

old_file=$(ls packaging/gentoo/derakht-cli-*.ebuild 2>/dev/null | head -1)
if [ -z "$old_file" ]; then
    echo "error: no ebuild found in packaging/gentoo/"
    exit 1
fi

new_file="packaging/gentoo/derakht-cli-${version}.ebuild"

if [ "$old_file" != "$new_file" ]; then
    mv "$old_file" "$new_file"
    echo "Renamed $old_file -> $new_file"
fi

# Update copyright year
sed -i "s/^# Copyright 1999-[0-9]*/# Copyright 1999-$(date +%Y)/" "$new_file"
echo "Stamped $version in $new_file"
