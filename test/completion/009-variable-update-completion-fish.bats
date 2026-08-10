# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests variable update completion under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# Helper: write a config with a fish variable set to $1 and a command using it.
_write_var_config() {
    local val="$1"
    cat > ~/.testcli.conf <<EOF
[env.fish]
set -gx __CLI_CFG_EXEC_SILENT y
set -gx __TEST_DYNAMIC_ITEMS ${val}

[commands]
dynamic-cmd
    \$__TEST_DYNAMIC_ITEMS: echo \0
EOF
}

@test "fish: variable-based completion returns initial items" {
    _write_var_config "alpha beta gamma"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "alpha"
    assert_line --partial "beta"
    assert_line --partial "gamma"
}

@test "fish: updated variable is reflected in next completion" {
    _write_var_config "alpha beta gamma"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "alpha"

    _write_var_config "delta epsilon zeta"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "delta"
}

@test "fish: two consecutive completions with different variable values produce different results" {
    _write_var_config "apple banana cherry"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "apple"

    _write_var_config "xray yankee zulu"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "xray"
    refute_line --partial "apple"
}

@test "fish: single-item variable update is reflected in completion" {
    _write_var_config "only"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "only"

    _write_var_config "replaced"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "replaced"
}

@test "fish: variable update from many items to fewer items is reflected" {
    _write_var_config "one two three four five"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "one"

    _write_var_config "just-one"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "just-one"
}

@test "fish: completion after three successive variable updates reflects last value" {
    _write_var_config "v1"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "v1"

    _write_var_config "v2"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "v2"

    _write_var_config "v3"
    run _fish_eval '_cli_complete_command 2 dynamic-cmd'
    assert_success
    assert_line --partial "v3"
}
