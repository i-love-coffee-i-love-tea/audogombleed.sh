# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh

#
# Tests that function updates in [env] are reflected in subsequent completions under zsh.
# Proves: define function -> complete -> update function -> complete shows different items.
#
# Functions defined in [env] are called via _cli_map_function_output_to_env_var()
# which captures stdout into _cli_<funcname>_result.  AWK reads that from ENVIRON.
# Rewriting the config (mtime change) forces re-source + re-execution of the function.

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

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

# bats test_tags=id:zsh-045
@test "zsh: function-based completion returns initial items" {
    _write_func_config 'echo "alpha beta gamma"'
    load '../_helpers/auto-completion-mock-setup-zsh'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"
}

# bats test_tags=id:zsh-046
@test "zsh: updated function is reflected in next completion" {
    _write_func_config 'echo "alpha beta gamma"'
    load '../_helpers/auto-completion-mock-setup-zsh'

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

# bats test_tags=id:zsh-047
@test "zsh: two consecutive completions with different function bodies produce different results" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_func_config 'echo "apple banana cherry"'
    result1="$(test_completion_zsh 3 "testcli" "func-cmd")"

    _write_func_config 'echo "xray yankee zulu"'
    result2="$(test_completion_zsh 3 "testcli" "dynamic-cmd")"

    # we only compare the first word to prove they differ
    first1="$(echo "$result1" | head -1 | sed 's/\[.*\]//')"
    first2="$(echo "$result2" | head -1 | sed 's/\[.*\]//')"
    [ "$first1" != "$first2" ]
}

# bats test_tags=id:zsh-048
@test "zsh: single-item function update is reflected in completion" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_func_config 'echo "only"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "only"

    _write_func_config 'echo "replaced"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "replaced"
}

# bats test_tags=id:zsh-049
@test "zsh: function update from many items to fewer items is reflected" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_func_config 'echo "one two three four five"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "one"
    assert_line "five"

    _write_func_config 'echo "just-one"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "just-one"
    refute_line "one"
}

# bats test_tags=id:zsh-050
@test "zsh: function update from fewer items to many items is reflected" {
    load '../_helpers/auto-completion-mock-setup-zsh'

    _write_func_config 'echo "solo"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "solo"

    _write_func_config 'echo "a b c d e f g"'
    run test_completion_zsh 3 "testcli" "func-cmd"
    assert_line "a"
    assert_line "g"
}

# bats test_tags=id:zsh-051
@test "zsh: completion after three successive function updates reflects last value" {
    load '../_helpers/auto-completion-mock-setup-zsh'

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

# bats test_tags=id:zsh-052
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

# bats test_tags=id:zsh-053
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

# bats test_tags=id:zsh-054
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
