# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
# Performance benchmarks (bash)
#
# Tests completion latency (the TAB-press experience) and execution latency.
# Dev README thresholds: 400ms sluggish, 200ms OK, 100ms good, <100ms very good.
#

LARGE_CONF_GENERATOR="./generate_large_config.sh"
MAX_COMPLETION_MS=${MAX_COMPLETION_MS:-150}
MAX_EXEC_MS=${MAX_EXEC_MS:-150}
MAX_LARGE_COMPLETION_MS=${MAX_LARGE_COMPLETION_MS:-250}

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

_time_ms() {
	local start end
	start=$(_now_ms)
	"$@" >/dev/null 2>&1
	end=$(_now_ms)
	echo $(( end - start ))
}

# Time a single _cli_complete_ call (the real TAB-press path).
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

setup_file() {
	echo "# setup_file" >&3
	load '../_helpers/common-setup'
	_common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
	echo "# teardown_file" >&3
	load '../_helpers/common-teardown'
	_common_teardown
}
setup() {
	load '../_test_helper/bats-support/load'
	load '../_test_helper/bats-assert/load'
}

# --- Execution benchmarks ---

# bats test_tags=id:bash-176
@test "bash: simple command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b echo hello)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

# bats test_tags=id:bash-177
@test "bash: hierarchical command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b install jar from file /tmp/test.jar)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

# --- Completion benchmarks (simple config) ---

# bats test_tags=id:bash-178
@test "bash: first-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 1 "testcli" "e")
	echo "# first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# bats test_tags=id:bash-179
@test "bash: second-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 2 "testcli" "echo" "")
	echo "# second-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# bats test_tags=id:bash-180
@test "bash: argument list completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 2 "testcli" "list-argument" "static" "")
	echo "# arg-list: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# bats test_tags=id:bash-181
@test "bash: hierarchical command completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 1 "testcli" "k" "")
	echo "# hierarchical: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# --- Completion benchmarks (large config) ---
# Swap in the large config, then restore after.

# bats test_tags=id:bash-182
@test "bash: large config — first-word completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 1 "testcli" "p")
	echo "# large first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

# bats test_tags=id:bash-183
@test "bash: large config — deep nesting completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 4 "testcli" "provision" "server" "bare-metal" "")
	echo "# large deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

# bats test_tags=id:bash-184
@test "bash: large config — argument completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 6 "testcli" "provision" "server" "bare-metal" "us-east" "deploy" "")
	echo "# large arg: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

# bats test_tags=id:bash-185
@test "bash: large config — 8-level deep nesting < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 8 "testcli" "deep" "level2" "level3" "level4" "level5" "level6" "level7" "level8-a")
	echo "# 8-level deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}
