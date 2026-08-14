#!/usr/bin/env bash
# release.d hook: convert "## Unreleased" section in CHANGELOG.md to
# "## <version> (<date>)". Removes the Unreleased header entirely.
# Uses $version (base) — the +N rebuild suffix is packaging metadata only.
#
# Exports from release.sh: $version
#
set -euo pipefail

changelog="CHANGELOG.md"

if [ ! -f "$changelog" ]; then
	echo "Warning: $changelog not found, skipping"
	exit 0
fi

if ! grep -q '^## Unreleased' "$changelog"; then
	echo "No '## Unreleased' section in $changelog, skipping"
	exit 0
fi

# Skip if the version section already exists (previous run stamped it)
if grep -q "^## $version" "$changelog"; then
	echo "Version $version already in $changelog, skipping stamping"
	exit 0
fi

today=$(date +%Y-%m-%d)

# Replace "## Unreleased" with just the version header.
# The content that was under Unreleased now falls under the new version.
sed -i '/^## Unreleased$/c\## '"$version"' ('"$today"')' "$changelog"

echo "Stamped $version in $changelog"
