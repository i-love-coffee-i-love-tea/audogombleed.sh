#!/usr/bin/env bash
# Generate SHA256 checksums for release artifacts.
#
# Usage: publish-checksums.sh <version> <artifact-dir>
#
# Writes checksums to SHA256SUMS-<version>.txt and optionally
# publishes to a GitHub Gist if GH_TOKEN has gist scope.
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "usage: publish-checksums.sh <version> <artifact-dir>" >&2
    exit 1
fi

version="$1"
artifact_dir="$2"
outfile="SHA256SUMS-${version}.txt"

# Collect all regular files from the artifact directory tree.
find "$artifact_dir" -type f -print0 | sort -z | while IFS= read -r -d '' f; do
    sha=$(sha256sum "$f" | cut -d' ' -f1)
    basename_f=$(basename "$f")
    echo "${sha}  ${basename_f}"
done > "$outfile"

if [ ! -s "$outfile" ]; then
    echo "error: no artifacts found in $artifact_dir" >&2
    exit 1
fi

echo "--- SHA256SUMS ---"
cat "$outfile"
echo "---"

# Optionally publish to a Gist if gh is available and token has gist scope.
if command -v gh &>/dev/null && [ -n "${GH_TOKEN:-}" ]; then
    gist_url=$(gh gist create "$outfile" \
        --public \
        --filename "$outfile" \
        -d "derakht-cli v${version} SHA256 checksums" \
        2>&1) && echo "Gist: $gist_url" || echo "Warning: could not create Gist" >&2
fi
