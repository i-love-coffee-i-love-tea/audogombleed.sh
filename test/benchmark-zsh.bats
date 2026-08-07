# vim:et:ts=4:sw=4

#
# Performance benchmarks (zsh)
#
# Tests completion latency (the TAB-press experience) and execution latency.
# Dev README thresholds: 400ms sluggish, 200ms OK, 100ms good, <100ms very good.
#

LARGE_CONF_GENERATOR="./generate_large_config.sh"
MAX_COMPLETION_MS=300
MAX_EXEC_MS=200
MAX_LARGE_COMPLETION_MS=400

# Portable millisecond timestamp (works on macOS and Linux).
_now_ms() {
	local t
	t=$(date +%s%N 2>/dev/null)
	if [[ "$t" =~ ^[0-9]+$ ]]; then
		echo $(( t / 1000000 ))
	elif command -v python3 &>/dev/null; then
		python3 -c 'import time; print(int(time.time()*1000))'
	else
		echo $(( $(date +%s) * 1000 ))
	fi
}

_time_ms() {
	local start end
	start=$(_now_ms)
	"$@" >/dev/null 2>&1
	end=$(_now_ms)
	echo $(( end - start ))
}

# Time a single _cli_complete_ call under zsh.
# Runs everything inside a single zsh process: source, set up, measure.
_zsh_timed_completion() {
	zsh -c '
		autoload -Uz compinit bashcompinit
		compinit -u
		bashcompinit
		source ./testcli
		_values() { :; }

		CURRENT=$1
		shift
		words=("$@")

		# Portable millisecond timestamp
		_now_ms() {
			local t
			t=$(date +%s%N 2>/dev/null)
			if [[ "$t" =~ ^[0-9]+$ ]]; then
				echo $(( t / 1000000 ))
			elif command -v python3 &>/dev/null; then
				python3 -c "import time; print(int(time.time()*1000))"
			else
				echo $(( $(date +%s) * 1000 ))
			fi
		}

		start=$(_now_ms)
		_cli_complete_
		end=$(_now_ms)

		echo $(( end - start ))
	' _ "$@"
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

@test "zsh: simple command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b echo hello)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

@test "zsh: hierarchical command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b install jar from file /tmp/test.jar)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

# --- Completion benchmarks (simple config) ---

@test "zsh: first-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_zsh_timed_completion 2 "testcli" "e")
	echo "# first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

@test "zsh: second-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_zsh_timed_completion 3 "testcli" "echo" "")
	echo "# second-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

@test "zsh: argument list completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_zsh_timed_completion 3 "testcli" "list-argument" "static" "")
	echo "# arg-list: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

@test "zsh: hierarchical command completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_zsh_timed_completion 2 "testcli" "k" "")
	echo "# hierarchical: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# --- Completion benchmarks (large config) ---

@test "zsh: large config — first-word completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_zsh_timed_completion 2 "testcli" "p")
	echo "# large first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

@test "zsh: large config — deep nesting completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_zsh_timed_completion 5 "testcli" "provision" "server" "bare-metal" "" "")
	echo "# large deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

@test "zsh: large config — argument completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_zsh_timed_completion 7 "testcli" "provision" "server" "bare-metal" "us-east" "deploy" "")
	echo "# large arg: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

@test "zsh: large config — 8-level deep nesting < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_zsh_timed_completion 9 "testcli" "deep" "level2" "level3" "level4" "level5" "level6" "level7" "level8-a")
	echo "# 8-level deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}
