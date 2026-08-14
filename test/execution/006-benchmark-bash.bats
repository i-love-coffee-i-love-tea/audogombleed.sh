# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
# Performance benchmarks (bash)
#
# Tests completion latency (the TAB-press experience) and execution latency.
# Dev README thresholds: 400ms sluggish, 200ms OK, 100ms good, <100ms very good.
#

LARGE_CONF_GENERATOR="./scripts/generate_large_config.sh"
MAX_COMPLETION_MS=${MAX_COMPLETION_MS:-150}
MAX_EXEC_MS=${MAX_EXEC_MS:-150}
MAX_LARGE_COMPLETION_MS=${MAX_LARGE_COMPLETION_MS:-250}

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; load '../_helpers/benchmark-helpers'; }

# --- Execution benchmarks ---

# bats test_tags=id:bash-176
@test "bash: simple command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b echo hello)
	echo "# exec: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_EXEC_MS"
}

# bats test_tags=id:bash-177
@test "bash: hierarchical command execution < ${MAX_EXEC_MS}ms" {
	local ms
	ms=$(_time_ms ./testcli -b install jar from file /tmp/test.jar)
	echo "# exec: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_EXEC_MS"
}

# --- Completion benchmarks (simple config) ---

# bats test_tags=id:bash-178
@test "bash: first-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 1 "testcli" "e")
	echo "# first-word: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_COMPLETION_MS"
}

# bats test_tags=id:bash-179
@test "bash: second-word completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 2 "testcli" "echo" "")
	echo "# second-word: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_COMPLETION_MS"
}

# bats test_tags=id:bash-180
@test "bash: argument list completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 2 "testcli" "list-argument" "static" "")
	echo "# arg-list: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_COMPLETION_MS"
}

# bats test_tags=id:bash-181
@test "bash: hierarchical command completion < ${MAX_COMPLETION_MS}ms" {
	local ms
	ms=$(_time_completion 1 "testcli" "k" "")
	echo "# hierarchical: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_COMPLETION_MS"
}

# --- Completion benchmarks (large config) ---
# Swap in the large config, then restore after.

# bats test_tags=id:bash-182
@test "bash: large config — first-word completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 1 "testcli" "p")
	echo "# large first-word: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_LARGE_COMPLETION_MS"
}

# bats test_tags=id:bash-183
@test "bash: large config — deep nesting completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 4 "testcli" "provision" "server" "bare-metal" "")
	echo "# large deep: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_LARGE_COMPLETION_MS"
}

# bats test_tags=id:bash-184
@test "bash: large config — argument completion < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 6 "testcli" "provision" "server" "bare-metal" "us-east" "deploy" "")
	echo "# large arg: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_LARGE_COMPLETION_MS"
}

# bats test_tags=id:bash-185
@test "bash: large config — 8-level deep nesting < ${MAX_LARGE_COMPLETION_MS}ms" {
	"$LARGE_CONF_GENERATOR" > ~/.testcli.conf
	local ms
	ms=$(_time_completion 8 "testcli" "deep" "level2" "level3" "level4" "level5" "level6" "level7" "level8-a")
	echo "# 8-level deep: ${ms}ms" >&3
	assert_at_most "$ms" "$MAX_LARGE_COMPLETION_MS"
}
