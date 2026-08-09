#!/usr/bin/env bash
# release.d hook: extract the embedded AWK script and lint it.
#
# Exports from release.sh: $script
# Requires: awk. Skips if awk does not support --lint.
#
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ln -sf "$PWD/$script" "$tmpdir/testcli"
awk_script=$("$tmpdir/testcli" --cli-print-awk-script 2>/dev/null)

if [ -z "$awk_script" ]; then
    echo "error: could not extract embedded AWK script from $script"
    exit 1
fi

echo "Linting embedded AWK script..."
echo "$awk_script" | awk --lint -f /dev/stdin 2>&1
echo "AWK lint passed."
