#!/usr/bin/env bash
# release.d hook: convert "## Unreleased" section in CHANGELOG.md to
# "## <version> (<date>)" and add a fresh "## Unreleased" header above it.
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

today=$(date +%Y-%m-%d)

# Replace "## Unreleased" with a fresh Unreleased header + new version header.
# Result: "## Unreleased\n\n## <version> (<date>)"
# The content that was under Unreleased now falls under the new version.
sed -i '/^## Unreleased$/c\## Unreleased\n\n## '"$version"' ('"$today"')' "$changelog"

echo "Stamped $version in $changelog"
