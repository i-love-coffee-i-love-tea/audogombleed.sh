# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:fish
#
# Tests help output under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: '?' shows all commands" {
    run _fish_run '?'
    assert_success
    [ "${#lines[@]}" -gt 0 ]
}

@test "fish: 'echo ?' shows echo help" {
    run _fish_run echo '?'
    assert_success
    assert_output --partial "echo"
}
