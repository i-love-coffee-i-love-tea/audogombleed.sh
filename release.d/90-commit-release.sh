#!/usr/bin/env bash
# release.d hook: stage and commit the release files.
#
# Exports from release.sh: $version $script $manpage $changelog
#
set -euo pipefail

git add "$script" "$manpage" "$changelog" packaging/ CHANGELOG.md
git commit -m "chore(release): bump version to $version"
