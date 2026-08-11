# vim:et:ts=2:sw=2

# Provides _fish_run() — execute the CLI under fish instead of bash.
# Usage in bats tests:  run _fish_run echo first second third
# Behaves like 'run ./testcli ...' but uses fish as the interpreter.

_fish_run() {
	fish ./testcli "$@"
}

# Run fish code with the testcli environment loaded.
# Creates a wrapper in $PWD so status filename resolves to the project
# directory, then appends the test code.
# Usage: run _fish_eval '_cli_getfirstwords e'
_fish_eval() {
	local code="$1"
	local tmp="$PWD/.fish-eval-test"
	cat > "$tmp" <<SCRIPT
#!/usr/bin/env fish
set -g __CLI_PROGNAME testcli
set -g __cli_wrapper_argv
source (path dirname (status filename))/derakht.fish
$code
SCRIPT
	chmod +x "$tmp"
	fish "$tmp"
	local rc=$?
	rm -f "$tmp"
	return $rc
}

# Run _cli_complete_ under fish with given commandline words and return completions.
# Usage: _fish_complete word1 word2 ...
# The first word is the program name.
_fish_complete() {
	fish -c '
		source ./testcli
		# Build the commandline words as fish would see them
		set -l cmdline $argv
		set -l prog $cmdline[1]
		set -l words $cmdline[2..-1]

		# Call the completion function
		_cli_complete_ $prog $words
	' "$@"
}
