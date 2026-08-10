#!/usr/bin/env bash
# Generate code coverage report for audogombleed.sh using kcov.
#
# Usage:
#   ./coverage.sh              # run all bash tests with coverage
#   ./coverage.sh --open       # run and open HTML report in browser
#   ./coverage.sh --zsh        # include zsh tests (limited — kcov is bash-only)
#
# Requirements:
#   - kcov (https://github.com/SimonKagstrom/kcov)
#   - bats submodules initialized (git submodule update --init --recursive)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COVERAGE_DIR="$SCRIPT_DIR/coverage"
OPEN_REPORT=false
RUN_ZSH=false

for arg in "$@"; do
    case "$arg" in
        --open)  OPEN_REPORT=true ;;
        --zsh)   RUN_ZSH=true ;;
        *)       echo "usage: $0 [--open] [--zsh]"; exit 1 ;;
    esac
done

if ! command -v kcov &>/dev/null; then
    echo "error: kcov not found. Install it:"
    echo "  macOS:  brew install kcov"
    echo "  Ubuntu: sudo apt-get install kcov"
    echo "  Or build from source: https://github.com/SimonKagstrom/kcov"
    exit 1
fi

if [ ! -x "$SCRIPT_DIR/test/_bats/bin/bats" ]; then
    echo "error: bats not found. Initialize submodules:"
    echo "  git submodule update --init --recursive"
    exit 1
fi

rm -rf "$COVERAGE_DIR"
mkdir -p "$COVERAGE_DIR/bash"

echo "Running bash tests with kcov..."
kcov \
    --bash-method=DEBUG \
    --bash-parse-files-in-dir="$SCRIPT_DIR" \
    --include-pattern=audogombleed.sh \
    --exclude-pattern=test,bats \
    "$COVERAGE_DIR/bash" \
    "$SCRIPT_DIR/test/_bats/bin/bats" "$SCRIPT_DIR/test/*/*-bash.bats "$SCRIPT_DIR/test/*/*-all.bats

if $RUN_ZSH; then
    echo ""
    echo "Running zsh tests (coverage data is bash-only)..."
    "$SCRIPT_DIR/test/_bats/bin/bats" "$SCRIPT_DIR/test/*/*-zsh.bats "$SCRIPT_DIR/test/*/*-all.bats
fi

echo ""
echo "Merging coverage data..."
mkdir -p "$COVERAGE_DIR/merged"
kcov --merge "$COVERAGE_DIR/merged" "$COVERAGE_DIR/bash"

echo ""
if [ -f "$COVERAGE_DIR/merged/audogombleed.sh/coverage.json" ]; then
    pct=$(python3 -c "
import json
d = json.load(open('$COVERAGE_DIR/merged/audogombleed.sh/coverage.json'))
print(f\"{d['percent_covered']:.1f}%\")
" 2>/dev/null || echo "N/A")
    echo "Coverage: $pct"
    echo "HTML report: $COVERAGE_DIR/merged/audogombleed.sh/index.html"
else
    echo "Warning: no coverage data generated. Check kcov output above."
fi

if $OPEN_REPORT && [ -f "$COVERAGE_DIR/merged/audogombleed.sh/index.html" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        open "$COVERAGE_DIR/merged/audogombleed.sh/index.html"
    else
        xdg-open "$COVERAGE_DIR/merged/audogombleed.sh/index.html" 2>/dev/null || true
    fi
fi
