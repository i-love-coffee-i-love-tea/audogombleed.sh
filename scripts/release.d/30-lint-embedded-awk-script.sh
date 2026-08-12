#!/usr/bin/env bash
# release.d hook: extract and lint all 4 embedded AWK scripts.
#
# Lints parser + validator AWK from both derakht.sh and derakht.fish.
# Exports from release.sh: $script
# Requires: awk. Skips if awk does not support --lint.
#
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

fish_script="derakht.fish"
errors=0

lint_awk() {
    local source="$1" flag="$2" label="$3"
    local awk_script
    awk_script=$("$source" "$flag" 2>/dev/null)
    if [ -z "$awk_script" ]; then
        echo "  error: could not extract $label from $source"
        errors=$((errors + 1))
        return
    fi
    # Only fail on AWK syntax errors (exit code 2), not runtime errors.
    # The validator AWK script prints runtime errors when run without a
    # config file — that's expected, not a lint failure.
    local rc=0
    echo "$awk_script" | awk --lint -f /dev/stdin 2>&1 || rc=$?
    if [ $rc -eq 2 ]; then
        echo "  error: AWK syntax error in $label from $source"
        errors=$((errors + 1))
    fi
}

# Create test wrappers for derakht.sh and derakht.fish
ln -sf "$PWD/$script" "$tmpdir/testcli-sh"
chmod +x "$tmpdir/testcli-sh"

echo "Linting embedded AWK scripts..."

lint_awk "$tmpdir/testcli-sh" --cli-print-awk-script       "parser (bash)"
lint_awk "$tmpdir/testcli-sh" --cli-print-validator-script  "validator (bash)"

if [ -f "$fish_script" ] && command -v fish &>/dev/null; then
    # For fish, we need to source the script and call the functions
    awk_parser=$(fish -c "source $fish_script; _cli_read_awk_script; printf '%s\n' \$__CLI_AWK_SCRIPT" 2>/dev/null || true)
    if [ -n "$awk_parser" ]; then
        rc=0
        echo "$awk_parser" | awk --lint -f /dev/stdin 2>&1 || rc=$?
        if [ $rc -eq 2 ]; then
            echo "  error: AWK syntax error in parser from $fish_script"
            errors=$((errors + 1))
        fi
    else
        echo "  warning: could not extract parser from $fish_script, skipping"
    fi

    awk_validator=$(fish -c "source $fish_script; _cli_read_validator_script; printf '%s\n' \$__CLI_VALIDATOR_SCRIPT" 2>/dev/null || true)
    if [ -n "$awk_validator" ]; then
        rc=0
        echo "$awk_validator" | awk --lint -f /dev/stdin 2>&1 || rc=$?
        if [ $rc -eq 2 ]; then
            echo "  error: AWK syntax error in validator from $fish_script"
            errors=$((errors + 1))
        fi
    else
        echo "  warning: could not extract validator from $fish_script, skipping"
    fi
else
    echo "  warning: fish not found or $fish_script missing, skipping fish AWK lint"
fi

if [ $errors -gt 0 ]; then
    echo "AWK lint: $errors error(s) found."
    exit 1
fi
echo "AWK lint passed."
