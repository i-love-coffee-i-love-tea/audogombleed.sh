#!/usr/bin/env bash
# Create a reproducible tarball.
# All timestamps are epoch 0, ownership is root:root, files are sorted by name.
#
# Usage: make-tarball.sh <output.tar.gz> <source-dir> [subdir]
#
# Examples:
#   make-tarball.sh /tmp/out.tar.gz /tmp/src/derakht-cli-2.0.0
#   make-tarball.sh /tmp/out.tar.gz /tmp/src derakht-cli-2.0.0
#   make-tarball.sh /tmp/out.tar.gz .             # tar current dir
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "usage: make-tarball.sh <output.tar.gz> <source-dir> [subdir]" >&2
    exit 1
fi

output="$1"
src_dir="$2"
subdir="${3:-}"

if [ -n "$subdir" ]; then
    tar czf "$output" \
        --sort=name \
        --mtime="@0" \
        --owner=0 \
        --group=0 \
        --numeric-owner \
        -C "$src_dir" "$subdir"
else
    tar czf "$output" \
        --sort=name \
        --mtime="@0" \
        --owner=0 \
        --group=0 \
        --numeric-owner \
        -C "$src_dir" .
fi
