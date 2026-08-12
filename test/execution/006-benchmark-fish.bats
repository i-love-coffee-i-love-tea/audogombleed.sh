# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
# Performance benchmarks (fish)
#
# Tests completion latency (the TAB-press experience) and execution latency.
# Dev README thresholds: 400ms sluggish, 200ms OK, 100ms good, <100ms very good.
# Fish thresholds are relaxed slightly due to fish startup overhead.
#

LARGE_CONF_GENERATOR="./scripts/generate_large_config.sh"
MAX_COMPLETION_MS=${MAX_COMPLETION_MS:-200}
MAX_EXEC_MS=${MAX_EXEC_MS:-200}
MAX_LARGE_COMPLETION_MS=${MAX_LARGE_COMPLETION_MS:-400}

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

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# --- Execution benchmarks ---

@test "fish: simple command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms _fish_run -b echo hello)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

@test "fish: hierarchical command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms _fish_run -b install jar from file /tmp/test.jar)
	echo "# exec: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_EXEC_MS" ]
}

# --- Completion benchmarks (simple config) ---

@test "fish: first-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_now_ms)
	_fish_eval '_cli_getfirstwords e' >/dev/null 2>&1
	local end=$(_now_ms)
	ms=$(( end - ms ))
	echo "# first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

@test "fish: second-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_now_ms)
	_fish_eval '_cli_complete_command 2 echo' >/dev/null 2>&1
	local end=$(_now_ms)
	ms=$(( end - ms ))
	echo "# second-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

@test "fish: argument list completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_now_ms)
	_fish_eval '_cli_complete_arg 0 "" list-argument static' >/dev/null 2>&1
	local end=$(_now_ms)
	ms=$(( end - ms ))
	echo "# arg-list: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

@test "fish: hierarchical command completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_now_ms)
	_fish_eval '_cli_complete_command 2 k' >/dev/null 2>&1
	local end=$(_now_ms)
	ms=$(( end - ms ))
	echo "# hierarchical: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_COMPLETION_MS" ]
}

# --- Completion benchmarks (large config) ---

@test "fish: large config — first-word completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_now_ms)
	_fish_eval '_cli_getfirstwords p' >/dev/null 2>&1
	local end=$(_now_ms)
	ms=$(( end - ms ))
	echo "# large first-word: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

@test "fish: large config — deep nesting completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_now_ms)
	_fish_eval '_cli_complete_command 4 provision server bare-metal' >/dev/null 2>&1
	local end=$(_now_ms)
	ms=$(( end - ms ))
	echo "# large deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

@test "fish: large config — argument completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_now_ms)
	_fish_eval '_cli_complete_arg 0 "" provision server bare-metal us-east deploy' >/dev/null 2>&1
	local end=$(_now_ms)
	ms=$(( end - ms ))
	echo "# large arg: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}

@test "fish: large config — 8-level deep nesting < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_now_ms)
	_fish_eval '_cli_complete_command 8 deep level2 level3 level4 level5 level6 level7' >/dev/null 2>&1
	local end=$(_now_ms)
	ms=$(( end - ms ))
	echo "# 8-level deep: ${ms}ms" >&3
	[ "$ms" -lt "$MAX_LARGE_COMPLETION_MS" ]
}
