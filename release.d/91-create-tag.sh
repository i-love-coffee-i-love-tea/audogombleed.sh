#!/usr/bin/env bash
# release.d hook: create a git tag for the release.
#
# Exports from release.sh: $version
#
set -euo pipefail

# Idempotent: skip if tag already exists
if git rev-parse "v$version" >/dev/null 2>&1; then
    echo "Tag v$version already exists"
    exit 0
fi

git tag "v$version"
echo "Tagged v$version — run 'git push && git push --tags' to publish"
