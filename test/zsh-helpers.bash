# vim:et:ts=2:sw=2

# Provides _zsh_run() — execute the CLI under zsh instead of bash.
# Usage in bats tests:  run _zsh_run echo first second third
# Behaves like 'run ./testcli ...' but uses zsh as the interpreter.

_zsh_run() {
	zsh ./testcli "$@"
}
