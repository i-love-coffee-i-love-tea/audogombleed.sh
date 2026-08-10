# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
# Performance benchmarks (zsh)
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
			local _date="date"
			command -v gdate &>/dev/null && _date="gdate"
			local ns
			ns=$("$_date" "+%s%N" 2>/dev/null)
			if [ "${#ns}" -gt 10 ]; then
				echo $(( 10#$ns / 1000000 ))
			else
				perl -MTime::HiRes -e "printf \"%d\n\", Time::HiRes::time()*1000"
			fi
		}

		start=$(_now_ms)
		_cli_complete_
		end=$(_now_ms)

		echo $(( end - start ))
	' _ "$@"
}

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load; }

# --- Execution benchmarks ---

# bats test_tags=id:zsh-112
@test "zsh: simple command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b echo hello)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

# bats test_tags=id:zsh-113
@test "zsh: hierarchical command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b install jar from file /tmp/test.jar)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

# --- Completion benchmarks (simple config) ---

# bats test_tags=id:zsh-114
@test "zsh: first-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_zsh_timed_completion 2 "testcli" "e")
	echo "# first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# bats test_tags=id:zsh-115
@test "zsh: second-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_zsh_timed_completion 3 "testcli" "echo" "")
	echo "# second-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# bats test_tags=id:zsh-116
@test "zsh: argument list completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_zsh_timed_completion 3 "testcli" "list-argument" "static" "")
	echo "# arg-list: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# bats test_tags=id:zsh-117
@test "zsh: hierarchical command completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_zsh_timed_completion 2 "testcli" "k" "")
	echo "# hierarchical: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# --- Completion benchmarks (large config) ---

# bats test_tags=id:zsh-118
@test "zsh: large config — first-word completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_zsh_timed_completion 2 "testcli" "p")
	echo "# large first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

# bats test_tags=id:zsh-119
@test "zsh: large config — deep nesting completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_zsh_timed_completion 5 "testcli" "provision" "server" "bare-metal" "" "")
	echo "# large deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

# bats test_tags=id:zsh-120
@test "zsh: large config — argument completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_zsh_timed_completion 7 "testcli" "provision" "server" "bare-metal" "us-east" "deploy" "")
	echo "# large arg: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

# bats test_tags=id:zsh-121
@test "zsh: large config — 8-level deep nesting < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_zsh_timed_completion 9 "testcli" "deep" "level2" "level3" "level4" "level5" "level6" "level7" "level8-a")
	echo "# 8-level deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}
