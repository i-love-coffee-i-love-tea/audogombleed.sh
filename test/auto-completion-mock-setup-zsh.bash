# vim:et:ts=2:sw=2

# Zsh completion test helper.
# In zsh, _cli_complete_ reads from $words and $CURRENT (not COMP_WORDS/COMP_CWORD).
# Zsh completions include [description] suffixes — that's a feature, not noise.
# Suppresses _values (only callable from a completion widget) and prints COMPREPLY.
#
# Usage in bats tests:
#   load 'auto-completion-mock-setup-zsh'
#   result="$(test_completion_zsh 3 "testcli" "echo")"
#
# Arguments: CURRENT program_name word1 word2 ...
#   CURRENT = the position of the word being completed (1-indexed, zsh convention)
#
# Output: one completion per line, with [description] suffixes preserved.

test_completion_zsh() {
	zsh -c '
		autoload -Uz compinit bashcompinit
		compinit -u
		bashcompinit
		source ./testcli

		# Suppress _values — it can only be called from a completion widget.
		_values() { :; }

		CURRENT=$1
		shift
		words=("$@")

		_cli_complete_

		printf "%s\n" "${COMPREPLY[@]}"
	' _ "$@"
}
