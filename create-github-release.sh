#!/usr/bin/env bash
# Create a GitHub release for the given version tag.
#
# This script is NOT part of the release.d pipeline. Run it after
# release.sh has committed and tagged the release:
#
#   ./release.sh 2.2.0
#   ./create-github-release.sh 2.2.0
#
# Requirements:
#   - gh (GitHub CLI) authenticated
#   - The tag must already exist locally (created by release.sh)
#   - A .deb package at ../derakht-cli_<version>_all.deb (optional)
#
set -euo pipefail

if [ $# -ne 1 ]; then
	echo "usage: $0 <version>"
	echo "  e.g. $0 2.2.0"
	echo
	echo "Creates a GitHub release with release notes from CHANGELOG.md."
	echo "The tag must already exist (created by release.sh)."
	exit 1
fi

version="$1"
tag="v${version}"

# Verify gh is available
if ! command -v gh &>/dev/null; then
	echo "error: gh (GitHub CLI) not found. Install it:"
	echo "  https://cli.github.com/"
	exit 1
fi

# Verify the tag exists
if ! git rev-parse "$tag" &>/dev/null; then
	echo "error: tag $tag not found. Run release.sh first."
	exit 1
fi

# Extract release notes from CHANGELOG.md
# Find the section between "## $version" and the next "## " heading.
notes_file=$(mktemp)
trap 'rm -f "$notes_file"' EXIT

in_section=false
while IFS= read -r line; do
	if [[ "$line" == "## $version"* ]]; then
		in_section=true
		continue
	fi
	if $in_section && [[ "$line" == "## "* ]]; then
		break
	fi
	if $in_section; then
		echo "$line" >> "$notes_file"
	fi
done < CHANGELOG.md

if [ ! -s "$notes_file" ]; then
	echo "warning: no release notes found for $version in CHANGELOG.md"
	echo "# Release $version" > "$notes_file"
fi

# Build asset list
assets=()
if [ -f "../derakht-cli_${version}_all.deb" ]; then
	assets+=("../derakht-cli_${version}_all.deb")
fi

# Create the release
echo "Creating GitHub release $tag..."
if [ ${#assets[@]} -gt 0 ]; then
	gh release create "$tag" \
		--title "$tag" \
		--notes-file "$notes_file" \
		"${assets[@]}"
else
	gh release create "$tag" \
		--title "$tag" \
		--notes-file "$notes_file"
fi

echo "Release $tag created: $(gh release view "$tag" --json url -q .url)"
