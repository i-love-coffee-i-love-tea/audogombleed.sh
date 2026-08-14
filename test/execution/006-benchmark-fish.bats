# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
# Performance benchmarks (fish)
#
# Tests completion latency (the TAB-press experience) and execution latency.
# Dev README thresholds: 400ms sluggish, 200ms OK, 100ms good, <100ms very good.
# Fish benchmarks source derakht.fish once per test, then time the completion
# call in-process (same pattern as bash/zsh benchmarks).
#

LARGE_CONF_GENERATOR="./scripts/generate_large_config.sh"
MAX_COMPLETION_MS=${MAX_COMPLETION_MS:-200}
MAX_EXEC_MS=${MAX_EXEC_MS:-200}
MAX_LARGE_COMPLETION_MS=${MAX_LARGE_COMPLETION_MS:-400}

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; load '../_helpers/benchmark-helpers'; }

# --- Execution benchmarks ---

@test "fish: simple command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms _fish_run -b echo hello)
	echo "# exec: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_EXEC_MS"
}

@test "fish: hierarchical command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms _fish_run -b install jar from file /tmp/test.jar)
	echo "# exec: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_EXEC_MS"
}

# --- Completion benchmarks (simple config) ---

@test "fish: first-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_fish_time_completion '_cli_getfirstwords e')
	echo "# first-word: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_COMPLETION_MS"
}

@test "fish: second-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_fish_time_completion '_cli_complete_command 2 echo')
	echo "# second-word: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_COMPLETION_MS"
}

@test "fish: argument list completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_fish_time_completion '_cli_complete_arg 0 "" list-argument static')
	echo "# arg-list: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_COMPLETION_MS"
}

@test "fish: hierarchical command completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_fish_time_completion '_cli_complete_command 2 k')
	echo "# hierarchical: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_COMPLETION_MS"
}

# --- Completion benchmarks (large config) ---

@test "fish: large config — first-word completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_fish_time_completion '_cli_getfirstwords p')
	echo "# large first-word: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_LARGE_COMPLETION_MS"
}

@test "fish: large config — deep nesting completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_fish_time_completion '_cli_complete_command 4 provision server bare-metal')
	echo "# large deep: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_LARGE_COMPLETION_MS"
}

@test "fish: large config — argument completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_fish_time_completion '_cli_complete_arg 0 "" provision server bare-metal us-east deploy')
	echo "# large arg: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_LARGE_COMPLETION_MS"
}

@test "fish: large config — 8-level deep nesting < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_fish_time_completion '_cli_complete_command 8 deep level2 level3 level4 level5 level6 level7')
	echo "# 8-level deep: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_LARGE_COMPLETION_MS"
}
