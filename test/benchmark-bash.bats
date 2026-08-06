# vim:et:ts=4:sw=4

#
# Performance benchmarks (bash)
#
# Tests completion latency (the TAB-press experience) and execution latency.
# Dev README thresholds: 400ms sluggish, 200ms OK, 100ms good, <100ms very good.
#

LARGE_CONF_GENERATOR="./generate_large_config.sh"
MAX_COMPLETION_MS=200
MAX_EXEC_MS=200
MAX_LARGE_COMPLETION_MS=400

_time_ms() {
	local start end
	start=$(date +%s%N)
	"$@" >/dev/null 2>&1
	end=$(date +%s%N)
	echo $(( (end - start) / 1000000 ))
}

# Time a single _cli_complete_ call (the real TAB-press path).
_time_completion() {
	local comp_cword="$1"
	shift
	local comp_words=("$@")
	local comp_line="${comp_words[*]}"

	source ./testcli

	local start end
	start=$(date +%s%N)
	COMP_CWORD=$comp_cword
	COMP_WORDS=("${comp_words[@]}")
	COMP_LINE="$comp_line"
	_cli_complete_
	end=$(date +%s%N)
	echo $(( (end - start) / 1000000 ))
}

setup_file() {
	echo "# setup_file" >&3
	load 'common-setup'
	_common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
	echo "# teardown_file" >&3
	load 'common-teardown'
	_common_teardown
}
setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
}

# --- Execution benchmarks ---

@test "bash: simple command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b echo hello)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

@test "bash: hierarchical command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b install jar from file /tmp/test.jar)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

# --- Completion benchmarks (simple config) ---

@test "bash: first-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 1 "testcli" "e")
	echo "# first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

@test "bash: second-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 2 "testcli" "echo" "")
	echo "# second-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

@test "bash: argument list completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 2 "testcli" "list-argument" "static" "")
	echo "# arg-list: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

@test "bash: hierarchical command completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 1 "testcli" "k" "")
	echo "# hierarchical: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# --- Completion benchmarks (large config) ---
# Swap in the large config, then restore after.

@test "bash: large config — first-word completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 1 "testcli" "p")
	echo "# large first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

@test "bash: large config — deep nesting completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 4 "testcli" "provision" "server" "bare-metal" "")
	echo "# large deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

@test "bash: large config — argument completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 6 "testcli" "provision" "server" "bare-metal" "us-east" "deploy" "")
	echo "# large arg: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

@test "bash: large config — 8-level deep nesting < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 8 "testcli" "deep" "level2" "level3" "level4" "level5" "level6" "level7" "level8-a")
	echo "# 8-level deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}
