# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish

#
# Tests that shell variable updates are reflected in subsequent completions under fish.
# Proves: set variable -> complete -> update variable -> complete shows different items.
#
# In derakht, $variable references in [commands] are resolved from ENVIRON
# at AWK parse time.  The config [env] section re-exports on every source,
# so to change the value between completions we must rewrite the config file
# (which also busts the mtime cache).

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

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

@test "fish: variable-based completion returns initial items" {
    _write_var_config "alpha beta gamma"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"
}

@test "fish: updated variable is reflected in next completion" {
    _write_var_config "alpha beta gamma"

    # first completion
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"

    # update the variable in the config and re-source
    _write_var_config "delta epsilon zeta"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "delta"
    assert_line "epsilon"
    assert_line "zeta"
}

@test "fish: two consecutive completions with different variable values produce different results" {
    _write_var_config "apple banana cherry"
    result1="$(_fish_eval '_cli_complete_command 2 dynamic-cmd')"

    _write_var_config "xray yankee zulu"
    result2="$(_fish_eval '_cli_complete_command 2 dynamic-cmd')"

    [ "$result1" != "$result2" ]
    [[ "$result1" == *"apple"* ]]
    [[ "$result2" == *"xray"* ]]
}

@test "fish: single-item variable update is reflected in completion" {
    _write_var_config "only"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "only"

    _write_var_config "replaced"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "replaced"
}

@test "fish: variable update from many items to fewer items is reflected" {
    _write_var_config "one two three four five"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "one"
    assert_line "five"

    _write_var_config "just-one"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "just-one"
    refute_line "one"
}

@test "fish: variable update from fewer items to many items is reflected" {
    _write_var_config "solo"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "solo"

    _write_var_config "a b c d e f g"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "a"
    assert_line "g"
}

@test "fish: completion after three successive variable updates reflects last value" {
    _write_var_config "v1"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "v1"

    _write_var_config "v2"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "v2"

    _write_var_config "v3"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "v3"
}

@test "fish: variable with spaces in values updates correctly" {
    _write_var_config "dir-a dir-b"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "dir-a"
    assert_line "dir-b"

    _write_var_config "mount-point-a mount-point-b mount-point-c"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_line "mount-point-a"
    assert_line "mount-point-b"
    assert_line "mount-point-c"
}
