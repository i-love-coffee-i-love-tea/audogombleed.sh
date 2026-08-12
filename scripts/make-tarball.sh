#!/usr/bin/env bash
# Create a reproducible tarball.
# Prefers GNU tar (gtar) for full reproducibility (--sort, --mtime, --owner).
# Falls back to system tar on macOS/FreeBSD where GNU tar is not installed.
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

# Prefer GNU tar (gtar) for reproducibility flags.
tar_cmd="tar"
if command -v gtar &>/dev/null; then
    tar_cmd="gtar"
fi

if [ "$tar_cmd" = "gtar" ]; then
    # GNU tar: full reproducibility
    if [ -n "$subdir" ]; then
        gtar czf "$output" \
            --sort=name \
            --mtime="@0" \
            --owner=0 \
            --group=0 \
            --numeric-owner \
            -C "$src_dir" "$subdir"
    else
        gtar czf "$output" \
            --sort=name \
            --mtime="@0" \
            --owner=0 \
            --group=0 \
            --numeric-owner \
            -C "$src_dir" .
    fi
else
    # BSD tar (macOS, FreeBSD): no --sort or --mtime support.
    # COPYFILE_DISABLE avoids macOS resource forks in the archive.
    export COPYFILE_DISABLE=1
    if [ -n "$subdir" ]; then
        tar czf "$output" -C "$src_dir" "$subdir"
    else
        tar czf "$output" -C "$src_dir" .
    fi
fi
