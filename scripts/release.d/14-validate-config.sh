#!/usr/bin/env bash
# release.d hook: validate config files against the formal grammar.
#
# When called with an argument, validates that single file.
# When called without arguments (as a release hook), validates example.conf
# and all test configs in test/_configs/.
#
# Skips symlinks in test/_configs/ (they point to _base*.conf which is
# validated separately).
#
# Exports from release.sh: (none needed)
#
set -euo pipefail

# Create a temporary symlink so the embedded script can determine its name.
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
ln -sf "$PWD/derakht.sh" "$tmpdir/validate"
chmod +x "$tmpdir/validate"

rc=0

# Single-file mode: validate the given config
if [ $# -ge 1 ]; then
    config="$1"
    if [ ! -f "$config" ]; then
        echo "error: config file '$config' not found"
        exit 1
    fi
    "$tmpdir/validate" --cli-validate-config "$config"
    exit $?
fi

# Release-hook mode: validate example.conf, dev.conf + all test configs
echo "Validating example.conf..."
"$tmpdir/validate" --cli-validate-config example.conf || rc=1

echo "Validating dev.conf..."
"$tmpdir/validate" --cli-validate-config dev.conf || rc=1

for conf in test/_configs/**/*.conf; do
    [ -f "$conf" ] || continue
    [ -L "$conf" ] && continue
    echo "Validating $conf..."
    "$tmpdir/validate" --cli-validate-config "$conf" || rc=1
done

if [ $rc -eq 0 ]; then
    echo "All configs valid."
else
    echo "error: some configs failed validation"
    exit 1
fi
