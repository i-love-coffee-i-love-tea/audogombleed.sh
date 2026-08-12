#!/usr/bin/env bash
set -euo pipefail

# Generate debian/changelog from CHANGELOG.md (single source of truth).
#
# Usage:
#   ./generate-debian-changelog.sh              # auto-detect version from derakht.sh
#   ./generate-debian-changelog.sh 2.0.0        # explicit version

if [ $# -ge 1 ]; then
    version="$1"
else
    version=$(grep '^__CLI_VERSION=' derakht.sh | cut -d'"' -f2)
    if [ -z "$version" ]; then
        echo "error: could not read version from derakht.sh"
        exit 1
    fi
fi

changelog_md="CHANGELOG.md"
changelog_deb="debian/changelog"

if [ ! -f "$changelog_md" ]; then
    echo "error: $changelog_md not found"
    exit 1
fi

# Extract the section for this version from CHANGELOG.md.
# Looks for "## X.Y.Z" and grabs everything until the next "## " or end of file.
section=$(awk -v ver="$version" '
    /^## / {
        if (found) exit
        if ($2 == ver) found = 1
        next
    }
    found { print }
' "$changelog_md")

if [ -z "$section" ]; then
    echo "error: no section found for version $version in $changelog_md"
    exit 1
fi

# Convert markdown to debian changelog entries:
# - "### Header" -> "  * [Header]" (subheading as prefix)
# - "- bullet text" -> "  * bullet text"
# - strip backticks, leading/trailing whitespace
entries=$(echo "$section" | awk '
    /^### / {
        sub(/^### /, "")
        header = $0
        next
    }
    /^- / {
        sub(/^- /, "")
        # strip backticks
        gsub(/`/, "")
        if (header != "") {
            printf "  * [%s] %s\n", header, $0
            header = ""
        } else {
            printf "  * %s\n", $0
        }
    }
')

if [ -z "$entries" ]; then
    echo "error: no entries parsed from CHANGELOG.md section for $version"
    exit 1
fi

rfc_date=$(date -R)

cat > "$changelog_deb" <<EOF
derakht-cli ($version) unstable; urgency=medium

$entries

 -- Steffen Kremsler <github.com@gobuki.org>  $rfc_date
EOF

echo "Generated $changelog_deb from $changelog_md (version $version)"
