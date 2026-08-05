# vim:et:ts=2:sw=2

# Provides _zsh_run() — execute the CLI under zsh instead of bash.
# Usage in bats tests:  run _zsh_run echo first second third
# Behaves like 'run ./testcli ...' but uses zsh as the interpreter.

_zsh_run() {
	zsh ./testcli "$@"
}

# Run _cli_complete_ under zsh with given COMP_WORDS and return completions.
# Usage: _zsh_complete word1 word2 ...
# The first word is the program name (COMP_WORDS[0]).
_zsh_complete() {
	zsh -c '
		autoload -Uz compinit bashcompinit
		compinit -u
		bashcompinit
		source ./testcli
		words=("$@")
		CURRENT=${#words[@]}
		_cli_complete_
		printf "%s\n" "${COMPREPLY[@]}"
	' _ "$@"
}
