#!/usr/bin/env bash
# release.d hook: validate that ADRs > 10 follow MADR format.
#
# Exports from release.sh: (none needed)
# Uses validate-madr.sh in this directory.
#
set -euo pipefail

"$(dirname "$0")/13-validate-madr.sh" docs/dev/adr/
