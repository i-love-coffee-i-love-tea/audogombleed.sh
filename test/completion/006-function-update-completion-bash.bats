# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:bash

#
# Tests that function updates in [env] are reflected in subsequent completions and execution.
# Proves: define function -> complete/execute -> update function -> complete/execute
# shows different items / runs updated code.
#
# Functions defined in [env] are called via _cli_map_function_output_to_env_var()
# which captures stdout into _cli_<funcname>_result.  AWK reads that from ENVIRON.
# Rewriting the config (mtime change) forces re-source + re-execution of the function.

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

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

# bats test_tags=id:bash-063
@test "bash: function-based completion returns initial items" {
    _write_func_config 'echo "alpha beta gamma"'
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$result" 'alpha beta gamma'
}

# bats test_tags=id:bash-064
@test "bash: updated function is reflected in next completion" {
    _write_func_config 'echo "alpha beta gamma"'
    load '../_helpers/auto-completion-mock-setup'

    result1="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$result1" 'alpha beta gamma'

    # update the function body in config
    _write_func_config 'echo "delta epsilon zeta"'
    result2="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$result2" 'delta epsilon zeta'
}

# bats test_tags=id:bash-065
@test "bash: two consecutive completions with different function bodies produce different results" {
    load '../_helpers/auto-completion-mock-setup'

    _write_func_config 'echo "apple banana cherry"'
    result1="$(test_completion 2 "testcli" "func-cmd")"

    _write_func_config 'echo "xray yankee zulu"'
    result2="$(test_completion 2 "testcli" "func-cmd")"

    [ "$result1" != "$result2" ]
    assert_equal "$result1" 'apple banana cherry'
    assert_equal "$result2" 'xray yankee zulu'
}

# bats test_tags=id:bash-066
@test "bash: single-item function update is reflected in completion" {
    load '../_helpers/auto-completion-mock-setup'

    _write_func_config 'echo "only"'
    result1="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$result1" 'only'

    _write_func_config 'echo "replaced"'
    result2="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$result2" 'replaced'
}

# bats test_tags=id:bash-067
@test "bash: function update from many items to fewer items is reflected" {
    load '../_helpers/auto-completion-mock-setup'

    _write_func_config 'echo "one two three four five"'
    result1="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$result1" 'one two three four five'

    _write_func_config 'echo "just-one"'
    result2="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$result2" 'just-one'
}

# bats test_tags=id:bash-068
@test "bash: function update from fewer items to many items is reflected" {
    load '../_helpers/auto-completion-mock-setup'

    _write_func_config 'echo "solo"'
    result1="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$result1" 'solo'

    _write_func_config 'echo "a b c d e f g"'
    result2="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$result2" 'a b c d e f g'
}

# bats test_tags=id:bash-069
@test "bash: completion after three successive function updates reflects last value" {
    load '../_helpers/auto-completion-mock-setup'

    _write_func_config 'echo "v1"'
    r1="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$r1" 'v1'

    _write_func_config 'echo "v2"'
    r2="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$r2" 'v2'

    _write_func_config 'echo "v3"'
    r3="$(test_completion 2 "testcli" "func-cmd")"
    assert_equal "$r3" 'v3'
}

# --- execution ---

# bats test_tags=id:bash-070
@test "bash: updated function is executed on command execution" {
    _write_func_config 'echo "alpha beta gamma"'

    run ./testcli func-cmd alpha
    assert_success
    assert_output "alpha"

    # update function — execution still works (function re-sourced)
    _write_func_config 'echo "delta epsilon zeta"'

    run ./testcli func-cmd delta
    assert_success
    assert_output "delta"
}

# bats test_tags=id:bash-071
@test "bash: function that changes its logic produces different execution results" {
    _write_func_config 'echo "version1"'

    run ./testcli func-cmd version1
    assert_success
    assert_output "version1"

    # change function to output different words — the command still
    # accepts the new word as valid because the command list is re-read
    _write_func_config 'echo "version2"'

    run ./testcli func-cmd version2
    assert_success
    assert_output "version2"
}

# bats test_tags=id:bash-072
@test "bash: function with dynamic logic reflects update in execution" {
    # function that computes its output
    _write_func_config 'for i in 1 2 3; do echo "item-$i"; done'

    run ./testcli func-cmd item-1
    assert_success
    assert_output "item-1"

    # update function to produce different computed output
    _write_func_config 'for i in a b c; do echo "entry-$i"; done'

    run ./testcli func-cmd entry-a
    assert_success
    assert_output "entry-a"
}
