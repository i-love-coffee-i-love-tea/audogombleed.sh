#!/usr/bin/env bash
# release.d hook: stage and commit the release files.
#
# Exports from release.sh: $full_version $script $manpage $changelog
#
set -euo pipefail

git add "$script" "$manpage" "$changelog" packaging/ CHANGELOG.md

# Idempotent: skip if nothing changed (e.g. re-running the release script)
if git diff --cached --quiet; then
    echo "Release commit already up to date for $full_version"
    exit 0
fi

git commit -m "chore(release): bump version to $full_version"
