#!/usr/bin/env bash
# release.d hook: add an empty "## Unreleased" section to CHANGELOG.md
# after tagging. This prepares the changelog for the next development cycle.
#
# Exports from release.sh: $version
#
set -euo pipefail

changelog="CHANGELOG.md"

if [ ! -f "$changelog" ]; then
    echo "Warning: $changelog not found, skipping"
    exit 0
fi

# Skip if Unreleased section already exists
if grep -q '^## Unreleased' "$changelog"; then
    echo "'## Unreleased' already in $changelog, skipping"
    exit 0
fi

# Insert "## Unreleased" after "# Changelog" and before the first "##" version header.
# This keeps the heading at the top of the version list.
# Insert blank line + "## Unreleased" + blank line after "# Changelog".
# Using a temp file because sed 'a' with embedded newlines is not portable.
tmpfile=$(mktemp)
awk '/^# Changelog$/ { print; print ""; print "## Unreleased"; next } { print }' "$changelog" > "$tmpfile"
mv "$tmpfile" "$changelog"

echo "Added '## Unreleased' to $changelog for next development cycle"
