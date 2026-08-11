#!/usr/bin/env bash
# release.d hook: validate all test config files against the formal grammar.
#
# Skips symlinks (they point to _base*.conf which is validated separately).
# Exports from release.sh: (none needed)
#
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
ln -sf "$PWD/derakht.sh" "$tmpdir/validate"
chmod +x "$tmpdir/validate"

rc=0
for conf in test/_configs/**/*.conf; do
    [ -f "$conf" ] || continue
    # Skip symlinks — they point to a base config that's validated on its own
    [ -L "$conf" ] && continue
    echo "Validating $conf..."
    "$tmpdir/validate" --cli-validate-config "$conf" || rc=1
done

if [ $rc -eq 0 ]; then
    echo "All test configs valid."
else
    echo "error: some test configs failed validation"
    exit 1
fi
