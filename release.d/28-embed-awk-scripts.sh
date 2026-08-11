#!/usr/bin/env bash
# release.d hook: embed standalone AWK scripts from lib/ into derakht.sh
# and derakht.fish. Ensures the release artifacts carry the latest AWK.
#
# Exports from release.sh: (none needed)
#
set -euo pipefail

bash lib/embed-awk.sh
