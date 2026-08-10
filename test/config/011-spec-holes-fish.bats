# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests spec holes and edge cases in argument parsing under fish
# Some tests will fail until the fish wrapper implements value type injection.

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: value type stores default in __CMD_ARG_VALUE" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-cmd: echo
    :arg:value:default_val
CONF
    run _fish_eval '_awk output=commands command_filter="test-cmd"'
    assert_success
    assert_line --partial 'default_val'
}

@test "fish: value type default is used when arg omitted" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
test-cmd: echo
    :arg:value:default_val
CONF
    run _fish_run test-cmd
    assert_success
    assert_output "default_val"
}

@test "fish: argument description with colons is preserved" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-cmd: echo
    :arg:list:a|b
CONF
    run _fish_eval '_awk output=commands command_filter="test-cmd"'
    assert_success
    [ "${#lines[@]}" -gt 0 ]
}

@test "fish: command word pipe expansion skips empty elements" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
test-cmd
    a||b: echo \0
CONF
    run _fish_run test-cmd a
    assert_success
    assert_output "a"
}

@test "fish: argument list pipe expansion skips empty elements" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-cmd: echo
    :arg:list:a||b
CONF
    run _fish_eval '_cli_complete_arg 0 "" test-cmd'
    assert_success
    assert_line "a"
    assert_line "b"
}

@test "fish: int_range with valid bounds completes" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-cmd: echo
    :arg:int_range:1-5
CONF
    run _fish_eval '_cli_complete_arg 0 "" test-cmd'
    assert_success
    assert_line "1"
    assert_line "5"
}

@test "fish: value type with ? suffix is accepted" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
test-cmd: echo
    :arg:value:default?
CONF
    run _fish_run test-cmd
    assert_success
    assert_output "default"
}
