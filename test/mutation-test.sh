#!/usr/bin/env bash
# Mutation testing for derakht.sh
#
# Applies targeted mutations to key code paths and runs the test suite
# to verify that tests catch the mutations. A "killed" mutation means
# the test suite detected the change; a "survived" mutation means the
# test suite has a gap.
#
# Usage:
#   ./test/mutation-test.sh                    # run all mutations
#   ./test/mutation-test.sh --filter "file_perm" # run matching mutations
#   ./test/mutation-test.sh --dry-run           # show mutations without running
#
# Requirements:
#   - bats (test/_bats/bin/bats)
#   - The full test suite must pass before running this
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$PROJECT_DIR/derakht.sh"
BACKUP="$PROJECT_DIR/derakht.sh.mutation-backup"
FILTER=""
DRY_RUN=false

while [ $# -gt 0 ]; do
	case "$1" in
		--filter) FILTER="$2"; shift 2 ;;
		--dry-run) DRY_RUN=true; shift ;;
		*) echo "usage: $0 [--filter PATTERN] [--dry-run]"; exit 1 ;;
	esac
done

killed=0
survived=0
skipped=0
total=0

cleanup() {
	cp "$BACKUP" "$TARGET"
	rm -f "$BACKUP"
}
trap cleanup EXIT

cp "$TARGET" "$BACKUP"

# Each mutation is: name | sed_command | test_file_pattern
# The sed_command modifies derakht.sh; test_file_pattern selects
# which tests to run (empty = run all bash tests).
mutations=(
	# File permission checks — should be caught by file-permissions tests
	"file_perm_negate|s/! -f \"\$_cfg_file\"/-f \"\$_cfg_file\"/|file-permissions"
	"file_perm_world_writable|s/ -perm -002 / ! -perm -002 /|file-permissions"

	# CLI name validation — should be caught by error-handling tests
	"progname_allow_dots|s/\[A-Za-z_\]\[A-Za-z0-9_\]\*/[A-Za-z_.][A-Za-z0-9_.]*/|error-handling"

	# Exit code handling — should be caught by exit-codes tests
	"exit_code_50|s/exit 50/exit 99/|exit-codes"
	"exit_code_53|s/exit 53/exit 99/|exit-codes"

	# Abbreviation — should be caught by abbreviation tests
	"abbrev_expand|s/CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS=\"y\"/CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS=\"n\"/|abbreviation"

	# Silent mode — should be caught by error-handling tests
	"silent_mode|s/CFG_EXEC_SILENT=\"y\"/CFG_EXEC_SILENT=\"n\"/|error-handling"

	# Config file detection — should be caught by error-handling tests
	"config_present|s/_cli_config_file_is_present/true/|error-handling"

	# AWK output mode — should be caught by awk-config-parser tests
	"awk_output_cmd|s/output=command_names/output=invalid/|awk-config-parser"

	# Help triggers — should be caught by help tests
	"help_trigger|s/\"\\?\"/\"!\"/|help-triggers"

	# Argument type handling — should be caught by argument-types tests
	"arg_type_string|s/STRING/INVALID/|argument-types"

	# mtime caching — should be caught by config-options tests
	"mtime_cache|s/_cfg_mtime != __CLI_PERMS_VALID_MTIME/1 == 1/|config-options"

	# Compgen portability — should be caught by auto-completion tests
	"compgen_negate|s/COMPREPLY\[@\]=\"\$word\"/COMPREPLY[@]=\"\"/|auto-completion"
)

for mutation_str in "${mutations[@]}"; do
	IFS='|' read -r name sed_cmd test_pattern <<< "$mutation_str"

	# Apply filter
	if [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]]; then
		continue
	fi

	total=$((total + 1))

	if $DRY_RUN; then
		echo "  [dry-run] $name: $sed_cmd"
		continue
	fi

	# Apply mutation
	if ! sed -i "$sed_cmd" "$TARGET" 2>/dev/null; then
		echo "  [skip] $name: sed command failed"
		skipped=$((skipped + 1))
		cp "$BACKUP" "$TARGET"
		continue
	fi

	# Verify the mutation was applied
	if diff -q "$TARGET" "$BACKUP" >/dev/null 2>&1; then
		echo "  [skip] $name: no change after sed"
		skipped=$((skipped + 1))
		continue
	fi

	# Run matching tests (search subdirectories: config/, execution/, etc.)
	if [ -n "$test_pattern" ]; then
		test_files=$(find "$SCRIPT_DIR" -name "*${test_pattern}-bash.bats" 2>/dev/null | tr '\n' ' ')
	else
		test_files=$(find "$SCRIPT_DIR" \( -name "*-bash.bats" -o -name "*-all.bats" \) 2>/dev/null | tr '\n' ' ')
	fi

	if [ -z "$test_files" ]; then
		echo "  [skip] $name: no matching test files"
		skipped=$((skipped + 1))
		cp "$BACKUP" "$TARGET"
		continue
	fi

	# Run tests with timeout
	test_output=$(timeout 120 "$PROJECT_DIR/test/_bats/bin/bats" $test_files --tap 2>&1 || true)

	if echo "$test_output" | grep -q "^not ok"; then
		echo "  [killed] $name"
		killed=$((killed + 1))
	else
		echo "  [survived] $name — tests passed, mutation not caught!"
		survived=$((survived + 1))
	fi

	# Restore original
	cp "$BACKUP" "$TARGET"
done

echo ""
echo "=== Mutation Test Results ==="
echo "Total:     $total"
echo "Killed:    $killed"
echo "Survived:  $survived"
echo "Skipped:   $skipped"
if [ "$total" -gt 0 ] && [ "$skipped" -lt "$total" ]; then
	score=$(awk "BEGIN {printf \"%.1f\", ($killed / ($total - $skipped)) * 100}")
	echo "Score:     ${score}% (killed / non-skipped)"
fi
