# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests AWK parser integration under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: _awk output=command_names returns commands" {
    run fish -c 'source ./testcli; count (_awk output=command_names)'
    assert_success
    [ "$output" -gt 0 ]
}

@test "fish: _awk output=commands returns command list" {
    run fish -c 'source ./testcli; count (_awk output=commands)'
    assert_success
    [ "$output" -gt 0 ]
}

@test "fish: _awk output=help returns help text" {
    run fish -c 'source ./testcli; count (_awk output=help do_format=1)'
    assert_success
    [ "$output" -gt 0 ]
}

@test "fish: _awk output=env returns env lines" {
    run fish -c 'source ./testcli; count (_awk output=env)'
    assert_success
    [ "$output" -gt 0 ]
}
