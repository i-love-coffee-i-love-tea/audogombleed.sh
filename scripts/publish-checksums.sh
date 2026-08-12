#!/usr/bin/env bash
# Publish SHA256 checksums for release artifacts to a GitHub Gist.
#
# Usage: publish-checksums.sh <version> <artifact-dir> [gh-auth-args...]
#
# Requires: gh (GitHub CLI) authenticated with gist scope.
# Prints the Gist URL to stdout.
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "usage: publish-checksums.sh <version> <artifact-dir>" >&2
    exit 1
fi

version="$1"
artifact_dir="$2"

if ! command -v gh &>/dev/null; then
    echo "error: gh (GitHub CLI) not found" >&2
    exit 1
fi

# Collect all regular files from the artifact directory tree.
checksums=$(mktemp)
trap 'rm -f "$checksums"' EXIT

find "$artifact_dir" -type f -print0 | sort -z | while IFS= read -r -d '' f; do
    sha=$(sha256sum "$f" | cut -d' ' -f1)
    basename_f=$(basename "$f")
    echo "${sha}  ${basename_f}"
done > "$checksums"

if [ ! -s "$checksums" ]; then
    echo "error: no artifacts found in $artifact_dir" >&2
    exit 1
fi

echo "--- checksums ---" >&2
cat "$checksums" >&2
echo "---" >&2

# Create a public Gist.
gist_url=$(gh gist create "$checksums" \
    --public \
    --filename "checksums-${version}.txt" \
    -d "derakht-cli v${version} SHA256 checksums" \
    2>&1)

echo "$gist_url"
