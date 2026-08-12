#!/usr/bin/env bash
# release.d hook: extract and lint all 4 embedded AWK scripts.
#
# Lints parser + validator AWK from both derakht.sh and derakht.fish.
# Exports from release.sh: $script
# Requires: gawk. Skips if awk does not support --lint.
#
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

fish_script="derakht.fish"
errors=0

# Minimal valid config so the validator has something to parse instead of
# producing runtime errors about a missing [commands] section.
minimal_config="[commands]
lint-test: echo ok
"

# Filter out gawk lint noise and validator runtime messages, keeping only
# real AWK syntax errors (lines like: awk: file:N: error: ...).
filter_noise() {
    grep -v \
        -e 'warning:' \
        -e 'error: config file has no' \
        -e 'error(s),.*warning(s)' \
    || true
}

lint_awk() {
    local source="$1" flag="$2" label="$3" input="${4:-/dev/null}"
    local awk_script
    awk_script=$("$source" "$flag" 2>/dev/null)
    if [ -z "$awk_script" ]; then
        echo "  error: could not extract $label from $source"
        errors=$((errors + 1))
        return
    fi
    # Write script to a temp file so stdin stays free for config input.
    local script_file="$tmpdir/lint-awk-$RANDOM.awk"
    echo "$awk_script" > "$script_file"
    # gawk --lint executes the script and reports both lint warnings and
    # runtime output on stderr.  We capture stderr, filter the noise, and
    # report only real syntax errors.
    local rc=0 raw_output filtered
    raw_output=$(awk --lint -f "$script_file" < "$input" 2>&1) || rc=$?
    rm -f "$script_file"
    if [ $rc -ne 0 ]; then
        filtered=$(echo "$raw_output" | filter_noise)
        if [ -n "$filtered" ]; then
            echo "  error: AWK syntax error in $label from $source"
            echo "$filtered"
            errors=$((errors + 1))
        fi
    fi
}

# Create test wrappers for derakht.sh and derakht.fish
ln -sf "$PWD/$script" "$tmpdir/testcli-sh"
chmod +x "$tmpdir/testcli-sh"

# Write minimal config for validator linting
config_file="$tmpdir/lint-test.conf"
echo "$minimal_config" > "$config_file"

echo "Linting embedded AWK scripts..."

lint_awk "$tmpdir/testcli-sh" --cli-print-awk-script       "parser (bash)"
lint_awk "$tmpdir/testcli-sh" --cli-print-validator-script  "validator (bash)" "$config_file"

if [ -f "$fish_script" ] && command -v fish &>/dev/null; then
    # For fish, we need to source the script and call the functions
    awk_parser=$(fish -c "source $fish_script; _cli_read_awk_script; printf '%s\n' \$__CLI_AWK_SCRIPT" 2>/dev/null || true)
    if [ -n "$awk_parser" ]; then
        rc=0
        echo "$awk_parser" > "$tmpdir/fish-parser.awk"
        raw_output=$(awk --lint -f "$tmpdir/fish-parser.awk" < /dev/null 2>&1) || rc=$?
        rm -f "$tmpdir/fish-parser.awk"
        if [ $rc -ne 0 ]; then
            filtered=$(echo "$raw_output" | filter_noise)
            if [ -n "$filtered" ]; then
                echo "  error: AWK syntax error in parser from $fish_script"
                echo "$filtered"
                errors=$((errors + 1))
            fi
        fi
    else
        echo "  warning: could not extract parser from $fish_script, skipping"
    fi

    awk_validator=$(fish -c "source $fish_script; _cli_read_validator_script; printf '%s\n' \$__CLI_VALIDATOR_SCRIPT" 2>/dev/null || true)
    if [ -n "$awk_validator" ]; then
        rc=0
        echo "$awk_validator" > "$tmpdir/fish-validator.awk"
        raw_output=$(awk --lint -f "$tmpdir/fish-validator.awk" < "$config_file" 2>&1) || rc=$?
        rm -f "$tmpdir/fish-validator.awk"
        if [ $rc -ne 0 ]; then
            filtered=$(echo "$raw_output" | filter_noise)
            if [ -n "$filtered" ]; then
                echo "  error: AWK syntax error in validator from $fish_script"
                echo "$filtered"
                errors=$((errors + 1))
            fi
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
