# vim:et:ts=2:sw=2

# Benchmark helpers — shared timing functions for performance tests.
#
# Usage in bats test files:
#   setup() { load '../_helpers/test-setup'; _test_load_bash; load '../_helpers/benchmark-helpers'; }

# Portable millisecond timestamp.
# gdate (GNU coreutils): %s%N gives seconds+nanoseconds.
# date (GNU): same. macOS BSD date: %N not supported, fall back to perl.
_now_ms() {
	local _date="date"
	command -v gdate &>/dev/null && _date="gdate"
	local ns
	ns=$("$_date" '+%s%N' 2>/dev/null)
	if [ "${#ns}" -gt 10 ]; then
		echo $(( 10#$ns / 1000000 ))
	else
		perl -MTime::HiRes -e 'printf "%d\n", Time::HiRes::time()*1000'
	fi
}

# Time a command invocation. Prints elapsed milliseconds.
_time_ms() {
	local start end
	start=$(_now_ms)
	"$@" >/dev/null 2>&1
	end=$(_now_ms)
	echo $(( end - start ))
}

# Time a single _cli_complete_ call (the real TAB-press path) under bash.
# Usage: _time_completion <COMP_CWORD> <COMP_WORDS...>
_time_completion() {
	local comp_cword="$1"
	shift
	local comp_words=("$@")
	local comp_line="${comp_words[*]}"

	source ./testcli

	local start end
	start=$(_now_ms)
	COMP_CWORD=$comp_cword
	COMP_WORDS=("${comp_words[@]}")
	COMP_LINE="$comp_line"
	_cli_complete_
	end=$(_now_ms)
	echo $(( end - start ))
}
