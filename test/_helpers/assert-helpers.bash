# vim:et:ts=2:sw=2

# Custom assertion helpers for patterns bats-assert doesn't cover directly.
# Auto-loaded by _test_load_bash/zsh/fish via test-setup.bash.

# Assert a value is not equal to another (for timeout/crash checks).
assert_not_equal() {
	if [ "$1" = "$2" ]; then
		batslib_print_header_for "${FUNCNAME[1]}"
		echo "expected: not equal to '$2'"
		echo "actual:   '$1'"
		return 1
	fi
}

# Assert a numeric value is at most a threshold.
assert_at_most() {
	local actual="$1" max="$2" msg="${3:-expected $actual <= $max}"
	if [ "$actual" -gt "$max" ]; then
		batslib_print_header_for "${FUNCNAME[1]}"
		echo "$msg"
		return 1
	fi
}

# Assert a string is non-empty.
assert_not_empty() {
	if [ -z "$1" ]; then
		batslib_print_header_for "${FUNCNAME[1]}"
		echo "expected: non-empty string"
		echo "actual:   ''"
		return 1
	fi
}
