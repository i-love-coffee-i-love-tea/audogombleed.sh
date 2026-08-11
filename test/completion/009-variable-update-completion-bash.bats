# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:bash

#
# Tests that shell variable updates are reflected in subsequent completions.
# Proves: set variable -> complete -> update variable -> complete shows different items.
#
# In derakht, $variable references in [commands] are resolved from ENVIRON
# at AWK parse time.  The config [env] section re-exports on every source,
# so to change the value between completions we must rewrite the config file
# (which also busts the mtime cache).

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# Helper: write a config with a variable set to $1 and a command using it.
_write_var_config() {
    local val="$1"
    cat > ~/.testcli.conf <<EOF
[env]
__CLI_CFG_EXEC_SILENT=y
export __TEST_DYNAMIC_ITEMS="$val"

[commands]
dynamic-cmd
    \$__TEST_DYNAMIC_ITEMS: echo \0
EOF
}

# bats test_tags=id:bash-073
@test "bash: variable-based completion returns initial items" {
    _write_var_config "alpha beta gamma"
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result" 'alpha beta gamma'
}

# bats test_tags=id:bash-074
@test "bash: updated variable is reflected in next completion" {
    _write_var_config "alpha beta gamma"
    load '../_helpers/auto-completion-mock-setup'

    # first completion
    result1="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result1" 'alpha beta gamma'

    # update the variable in the config and re-source
    _write_var_config "delta epsilon zeta"
    result2="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result2" 'delta epsilon zeta'
}

# bats test_tags=id:bash-075
@test "bash: two consecutive completions with different variable values produce different results" {
    _write_var_config "apple banana cherry"
    load '../_helpers/auto-completion-mock-setup'
    result1="$(test_completion 2 "testcli" "dynamic-cmd")"

    _write_var_config "xray yankee zulu"
    result2="$(test_completion 2 "testcli" "dynamic-cmd")"

    [ "$result1" != "$result2" ]
    assert_equal "$result1" 'apple banana cherry'
    assert_equal "$result2" 'xray yankee zulu'
}

# bats test_tags=id:bash-076
@test "bash: single-item variable update is reflected in completion" {
    _write_var_config "only"
    load '../_helpers/auto-completion-mock-setup'
    result1="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result1" 'only'

    _write_var_config "replaced"
    result2="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result2" 'replaced'
}

# bats test_tags=id:bash-077
@test "bash: variable update from many items to fewer items is reflected" {
    _write_var_config "one two three four five"
    load '../_helpers/auto-completion-mock-setup'
    result1="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result1" 'one two three four five'

    _write_var_config "just-one"
    result2="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result2" 'just-one'
}

# bats test_tags=id:bash-078
@test "bash: variable update from fewer items to many items is reflected" {
    _write_var_config "solo"
    load '../_helpers/auto-completion-mock-setup'
    result1="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result1" 'solo'

    _write_var_config "a b c d e f g"
    result2="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result2" 'a b c d e f g'
}

# bats test_tags=id:bash-079
@test "bash: completion after three successive variable updates reflects last value" {
    _write_var_config "v1"
    load '../_helpers/auto-completion-mock-setup'
    r1="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$r1" 'v1'

    _write_var_config "v2"
    r2="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$r2" 'v2'

    _write_var_config "v3"
    r3="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$r3" 'v3'
}

# bats test_tags=id:bash-080
@test "bash: variable with spaces in values updates correctly" {
    _write_var_config "dir-a dir-b"
    load '../_helpers/auto-completion-mock-setup'
    result1="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result1" 'dir-a dir-b'

    _write_var_config "mount-point-a mount-point-b mount-point-c"
    result2="$(test_completion 2 "testcli" "dynamic-cmd")"
    assert_equal "$result2" 'mount-point-a mount-point-b mount-point-c'
}
