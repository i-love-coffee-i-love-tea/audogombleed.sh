#!/usr/bin/env bash
# Embed standalone AWK scripts from lib/ into derakht.sh and derakht.fish.
# Idempotent: running multiple times produces the same result.
#
# For derakht.sh:  replaces heredoc body (bash heredoc = zero escaping).
# For derakht.fish: generates printf '%s\n' function (escaped \ and ' only).
#
# Usage:
#   lib/embed-awk.sh                        # embed both (defaults)
#   lib/embed-awk.sh parser  [file.awk]     # embed parser only
#   lib/embed-awk.sh validator [file.awk]   # embed validator only
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SH="$REPO_DIR/derakht.sh"
FISH="$REPO_DIR/derakht.fish"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# ── Embed parser into derakht.sh ──
embed_sh_parser() {
    local awk_file="$1"
    awk -v parser="$awk_file" '
    BEGIN {
        while ((getline line < parser) > 0) p = p line "\n"
        close(parser)
        sub(/\n$/, "", p)
    }
    { lines[NR] = $0 }
    END {
        ps = pe = 0
        for (i = 1; i <= NR; i++) {
            if (lines[i] == "# __MAIN_AWK_PARSER__") ps = i
            if (lines[i] == "MAIN_AWK_EOF")          pe = i
        }
        skip = 0
        for (i = 1; i <= NR; i++) {
            if (i == ps + 1) { printf "%s", p; skip = 1; continue }
            if (i == pe)     { skip = 0; print lines[i]; continue }
            if (!skip) print lines[i]
        }
    }
    ' "$SH" > "$SH.tmp" && mv "$SH.tmp" "$SH"
}

# ── Embed validator into derakht.sh ──
embed_sh_validator() {
    local awk_file="$1"
    awk -v validator="$awk_file" '
    BEGIN {
        while ((getline line < validator) > 0) v = v line "\n"
        close(validator)
        sub(/\n$/, "", v)
    }
    { lines[NR] = $0 }
    END {
        vs = ve = 0
        for (i = 1; i <= NR; i++) {
            if (lines[i] ~ /^read -r -d.*CLI_VALIDATOR/) vs = i + 1
            if (lines[i] == "VALIDATOR_AWK_EOF")          ve = i
        }
        skip = 0
        for (i = 1; i <= NR; i++) {
            if (i == vs) { printf "%s", v; skip = 1; continue }
            if (i == ve) { skip = 0; print lines[i]; continue }
            if (!skip) print lines[i]
        }
    }
    ' "$SH" > "$SH.tmp" && mv "$SH.tmp" "$SH"
}

# ── Generate a fish function from an AWK file ──
# Uses printf '%s\n' with single-quoted arguments.
# Escapes: \\ -> \\\\ (fish reduces \\ to \) and ' -> '\''
generate_fish_func() {
    local func_name="$1" var_name="$2" awk_file="$3" out_file="$4"
    {
        printf 'function %s\n' "$func_name"
        printf '    if test -n "$%s"\n' "$var_name"
        printf '        return\n'
        printf '    end\n'
        printf '    set -g %s \\\n' "$var_name"
        local last_line
        last_line=$(tail -1 "$awk_file")
        sed -e 's/\\/\\\\/g' -e "s/'/'\\\\''/g" "$awk_file" | head -n -1 | while IFS= read -r line; do
            printf "        '%s' \\\\\n" "$line"
        done
        printf "        '%s'\n" "$(echo "$last_line" | sed -e 's/\\/\\\\/g' -e "s/'/'\\\\''/g")"
        printf 'end\n'
    } > "$out_file"
}

# ── Replace a fish function by finding its comment header ──
replace_fish_func() {
    local comment_pattern="$1" new_func_file="$2"
    local start end
    start=$(grep -n "$comment_pattern" "$FISH" | head -1 | cut -d: -f1)
    [ -n "$start" ] || { echo "error: could not find '$comment_pattern' in $FISH" >&2; return 1; }
    end=$(awk "NR > $start && /^end$/ { print NR; exit }" "$FISH")

    {
        # Lines up to and including the comment header
        head -n "$start" "$FISH"
        # New function (the comment is already above, so skip the old function body)
        cat "$new_func_file"
        # Lines after the old function's closing end
        tail -n +$((end + 1)) "$FISH"
    } > "$FISH.tmp" && mv "$FISH.tmp" "$FISH"
}

# ── Commands ──

embed_parser() {
    local awk_file="${1:-$SCRIPT_DIR/derakht-parser.awk}"
    [ -f "$awk_file" ] || { echo "error: $awk_file not found" >&2; exit 1; }
    embed_sh_parser "$awk_file"
    echo "Embedded parser into $SH"
    generate_fish_func "_cli_read_awk_script" "__CLI_AWK_SCRIPT" "$awk_file" "$tmpdir/pfunc"
    replace_fish_func "^# Extract the embedded AWK parser from derakht" "$tmpdir/pfunc"
    echo "Embedded parser into $FISH"
}

embed_validator() {
    local awk_file="${1:-$SCRIPT_DIR/derakht-validator.awk}"
    [ -f "$awk_file" ] || { echo "error: $awk_file not found" >&2; exit 1; }
    embed_sh_validator "$awk_file"
    echo "Embedded validator into $SH"
    generate_fish_func "_cli_read_validator_script" "__CLI_VALIDATOR_SCRIPT" "$awk_file" "$tmpdir/vfunc"
    replace_fish_func "^# Extract the embedded AWK validator from derakht" "$tmpdir/vfunc"
    echo "Embedded validator into $FISH"
}

case "${1:-all}" in
    parser)    embed_parser "${2:-}" ;;
    validator) embed_validator "${2:-}" ;;
    all)       embed_parser; embed_validator ;;
    *)         echo "usage: embed-awk.sh [parser|validator|all] [file.awk]" >&2; exit 1 ;;
esac
