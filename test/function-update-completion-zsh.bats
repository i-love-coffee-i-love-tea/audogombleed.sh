# vim:et:ts=4:sw=4

#
# Tests that function updates in [env] are reflected in subsequent completions under zsh.
# Proves: define function -> complete -> update function -> complete shows different items.
#
# Functions defined in [env] are called via _cli_map_function_output_to_env_var()
# which captures stdout into _cli_<funcname>_result.  AWK reads that from ENVIRON.
# Rewriting the config (mtime change) forces re-source + re-execution of the function.

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load 'common-teardown'
    _common_teardown
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'zsh-helpers'
}

# Helper: write a config with a function that echoes $1 and a command using it.
_write_func_config() {
    local func_body="$1"
    cat > ~/.testcli.conf <<EOF
[env]
__CLI_CFG_EXEC_SILENT=y
my_words() { ${func_body}; }

[commands]
func-cmd
    &my_words: echo \0
EOF
}

# --- completion ---

@test "zsh: function-based completion returns initial items" {
    _write_func_config 'echo "alpha beta gamma"'
    load 'auto-completion-mock-setup-zsh'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"
}

@test "zsh: updated function is reflected in next completion" {
    _write_func_config 'echo "alpha beta gamma"'
    load 'auto-completion-mock-setup-zsh'

    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"

    _write_func_config 'echo "delta epsilon zeta"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "delta"
    assert_line "epsilon"
    assert_line "zeta"
}

@test "zsh: two consecutive completions with different function bodies produce different results" {
    load 'auto-completion-mock-setup-zsh'

    _write_func_config 'echo "apple banana cherry"'
    result1="$(test_completion_zsh 3 "testcli" "func-cmd")"

    _write_func_config 'echo "xray yankee zulu"'
    result2="$(test_completion_zsh 3 "testcli" "dynamic-cmd")"

    # we only compare the first word to prove they differ
    first1="$(echo "$result1" | head -1 | sed 's/\[.*\]//')"
    first2="$(echo "$result2" | head -1 | sed 's/\[.*\]//')"
    [ "$first1" != "$first2" ]
}

@test "zsh: single-item function update is reflected in completion" {
    load 'auto-completion-mock-setup-zsh'

    _write_func_config 'echo "only"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "only"

    _write_func_config 'echo "replaced"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "replaced"
}

@test "zsh: function update from many items to fewer items is reflected" {
    load 'auto-completion-mock-setup-zsh'

    _write_func_config 'echo "one two three four five"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "one"
    assert_line "five"

    _write_func_config 'echo "just-one"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "just-one"
    refute_line "one"
}

@test "zsh: function update from fewer items to many items is reflected" {
    load 'auto-completion-mock-setup-zsh'

    _write_func_config 'echo "solo"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "solo"

    _write_func_config 'echo "a b c d e f g"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "a"
    assert_line "g"
}

@test "zsh: completion after three successive function updates reflects last value" {
    load 'auto-completion-mock-setup-zsh'

    _write_func_config 'echo "v1"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "v1"

    _write_func_config 'echo "v2"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "v2"

    _write_func_config 'echo "v3"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "v3"
}

# --- execution ---

@test "zsh: updated function is executed on command execution" {
    _write_func_config 'echo "alpha beta gamma"'

    run _zsh_run func-cmd alpha
    assert_success
    assert_output "alpha"

    _write_func_config 'echo "delta epsilon zeta"'

    run _zsh_run func-cmd delta
    assert_success
    assert_output "delta"
}

@test "zsh: function that changes its logic produces different execution results" {
    _write_func_config 'echo "version1"'

    run _zsh_run func-cmd version1
    assert_success
    assert_output "version1"

    _write_func_config 'echo "version2"'

    run _zsh_run func-cmd version2
    assert_success
    assert_output "version2"
}

@test "zsh: function with dynamic logic reflects update in execution" {
    _write_func_config 'for i in 1 2 3; do echo "item-$i"; done'

    run _zsh_run func-cmd item-1
    assert_success
    assert_output "item-1"

    _write_func_config 'for i in a b c; do echo "entry-$i"; done'

    run _zsh_run func-cmd entry-a
    assert_success
    assert_output "entry-a"
}
