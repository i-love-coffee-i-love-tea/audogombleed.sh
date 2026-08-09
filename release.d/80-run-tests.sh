#!/usr/bin/env bash
# release.d hook: run the full test suite before committing.
#
# Exports from release.sh: (none needed)
#
set -euo pipefail

test/bats/bin/bats test/*.bats
