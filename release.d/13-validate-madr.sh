#!/usr/bin/env bash
# Validate that ADRs numbered > 10 follow MADR format and have unique numbers.
#
# ADRs 001–010 are considered legacy and are not linted.
# ADRs 011+ must follow the MADR spec (https://adr.github.io/madr/):
#   - YAML front matter with at least `status` and `date`
#   - Title: # Short title (no ADR-NNN prefix)
#   - Required sections: Context and Problem Statement, Decision Outcome
#   - Required subsection: Consequences (under Decision Outcome)
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

    # YAML front matter: must start with ---
    if ! echo "$content" | head -1 | grep -q '^---$'; then
        freport "missing YAML front matter (must start with ---)"
    fi

    # YAML front matter: must contain status field
    if ! echo "$content" | head -20 | grep -qE '^status:'; then
        freport "missing 'status:' in YAML front matter"
    fi

    # YAML front matter: must contain date field
    if ! echo "$content" | head -20 | grep -qE '^date:'; then
        freport "missing 'date:' in YAML front matter"
    fi

    # Title: must be # Short title (no ADR-NNN prefix)
    local title_line
    title_line=$(echo "$content" | grep '^# ' | head -1 || true)
    if [ -z "$title_line" ]; then
        freport "missing title (expected: # Short title)"
    elif echo "$title_line" | grep -qE '^# ADR-[0-9]'; then
        freport "title uses old format '# ADR-NNN: Title' — MADR requires '# Short title' without prefix"
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

    # Decision Outcome must contain "because" justification
    local decision_section
    decision_section=$(echo "$content" | sed -n '/^## Decision Outcome/,/^## /p')
    if ! echo "$decision_section" | grep -q 'because'; then
        freport "Decision Outcome missing 'because' justification"
    fi

    # Consequences must use "Good, because" / "Bad, because" format
    local consequences_section
    consequences_section=$(echo "$content" | sed -n '/^### Consequences/,/^##\|^### /p')
    if [ -n "$consequences_section" ]; then
        if ! echo "$consequences_section" | grep -qE '(Good|Bad|Neutral), because'; then
            freport "Consequences must use 'Good, because' / 'Bad, because' / 'Neutral, because' format"
        fi
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
