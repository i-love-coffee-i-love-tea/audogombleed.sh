#!/usr/bin/env bash
# release.d hook: validate CHANGELOG.md is ready for release stamping.
# Uses $version (base) — changelog entries don't carry the +N rebuild suffix.
#
# Exports from release.sh: $version
#
# +----------------+----------------+------+-------------------------------+
# | ## Unreleased  | ## <version>   |      | Reason                        |
# +----------------+----------------+------+-------------------------------+
# | yes            | yes            | FAIL | Both exist — broken state     |
# | yes            | no             | OK   | Ready to stamp                |
# | no             | yes            | OK   | Already stamped or post-tag   |
# | no             | no             | FAIL | Nothing to release            |
# +----------------+----------------+------+-------------------------------+
#
set -euo pipefail

changelog="CHANGELOG.md"

if [ ! -f "$changelog" ]; then
    echo "error: $changelog not found"
    exit 1
fi

has_unreleased=false
has_version=false
grep -q '^## Unreleased' "$changelog" && has_unreleased=true
grep -q "^## $version" "$changelog" && has_version=true

if $has_unreleased && $has_version; then
    echo "error: $changelog: both '## Unreleased' and '## $version' exist"
    exit 1
fi

if $has_unreleased || $has_version; then
    exit 0
fi

echo "error: $changelog: no '## Unreleased' or '## $version' section found"
exit 1
