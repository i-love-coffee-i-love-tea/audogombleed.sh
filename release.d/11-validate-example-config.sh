#!/usr/bin/env bash
# release.d hook: validate example.conf against the config grammar.
#
# Exports from release.sh: (none needed)
# Uses 14-validate-config.sh in this directory.
#
set -euo pipefail

"$(dirname "$0")/14-validate-config.sh" example.conf
