#!/usr/bin/env bash
# release.d hook: stage and commit the release files.
#
# Exports from release.sh: $version $script $manpage $changelog
#
set -euo pipefail

git add "$script" "$manpage" "$changelog" packaging/
git commit -m "Bump version to $version"
