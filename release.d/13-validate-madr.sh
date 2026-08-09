#!/usr/bin/env bash
# Validate that ADRs numbered > 10 follow MADR format and have unique numbers.
#
# Usage:
#   ./validate-madr.sh docs/dev/adr/
#   ./validate-madr.sh docs/dev/adr/011-formalize-config-grammar.md
#
# Exit 0 if valid, exit 1 if errors found.
set -euo pipefail

errors=0

report() {
    echo "$1" >&2
    errors=$((errors + 1))
}

validate_adr() {
    local file="$1"
    local nr
    nr=$(basename "$file" | grep -oE '^[0-9]+' || true)

    # Only lint ADRs > 10
    if [ -z "$nr" ] || [ "$nr" -le 10 ]; then
        return 0
    fi

    local ferrors=0
    local content
    content=$(<"$file")

    freport() {
        echo "$file: $1" >&2
        ferrors=$((ferrors + 1))
    }

    # Title must match: # ADR-NNN: Title
    local title_nr
    title_nr=$(echo "$content" | grep -oE '^# ADR-([0-9]+)' | grep -oE '[0-9]+' || true)
    if [ -z "$title_nr" ]; then
        freport "missing MADR title (expected: # ADR-NNN: Title)"
    elif [ "$title_nr" != "$nr" ]; then
        freport "filename number ($nr) does not match title number ($title_nr)"
    fi

    # Metadata: * Status:
    if ! echo "$content" | grep -qE '^\* Status: '; then
        freport "missing '* Status:' metadata"
    fi

    # Metadata: * Date:
    if ! echo "$content" | grep -qE '^\* Date: '; then
        freport "missing '* Date:' metadata"
    fi

    # Required section: ## Context and Problem Statement
    if ! echo "$content" | grep -q '^## Context and Problem Statement'; then
        freport "missing '## Context and Problem Statement' section"
    fi

    # Required section: ## Decision Outcome
    if ! echo "$content" | grep -q '^## Decision Outcome'; then
        freport "missing '## Decision Outcome' section"
    fi

    # Required subsection: ### Consequences (under Decision Outcome)
    if ! echo "$content" | grep -q '^### Consequences'; then
        freport "missing '### Consequences' subsection"
    fi

    errors=$((errors + ferrors))
}

if [ $# -eq 0 ]; then
    echo "usage: $0 <adr-file-or-directory>" >&2
    exit 1
fi

# Collect all ADR files
adr_files=()
for target in "$@"; do
    if [ -d "$target" ]; then
        for file in "$target"/*.md; do
            [ -f "$file" ] || continue
            adr_files+=("$file")
        done
    elif [ -f "$target" ]; then
        adr_files+=("$target")
    else
        echo "error: '$target' not found" >&2
        exit 1
    fi
done

# Check for duplicate ADR numbers
declare -A seen_numbers
for file in "${adr_files[@]}"; do
    nr=$(basename "$file" | grep -oE '^[0-9]+' || true)
    [ -z "$nr" ] && continue
    if [ -n "${seen_numbers[$nr]+_}" ]; then
        report "duplicate ADR number $nr: $file and ${seen_numbers[$nr]}"
    else
        seen_numbers[$nr]="$file"
    fi
done

# Validate each ADR
for file in "${adr_files[@]}"; do
    validate_adr "$file"
done

if [ "$errors" -gt 0 ]; then
    echo "$errors error(s) found" >&2
    exit 1
fi

echo "All ADRs pass MADR validation."
