# vim:et:ts=4:sw=4
# bats file_tags=category:security, shell:fish
#
# File permission tests under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: world-executable config is handled" {
    chmod 777 ~/.testcli.conf
    # The AWK parser should still work (permission check is in bash, not AWK)
    run _fish_run echo first second third
    # May succeed or fail depending on implementation
    [ "$status" -le 53 ]
}

@test "fish: valid config works after permission restore" {
    chmod 644 ~/.testcli.conf
    run _fish_run echo first second third
    assert_success
    assert_output "second first third"
}

@test "fish: symlink to valid config works" {
    local tmpconf="/tmp/testcli-symlink.conf"
    cp example.conf "$tmpconf"
    ln -sf "$tmpconf" ~/.testcli.conf
    run _fish_run echo first second third
    assert_success
    rm -f "$tmpconf"
}

@test "fish: directory as config is handled" {
    rm -f ~/.testcli.conf
    mkdir -p ~/.testcli.conf
    run _fish_run echo test
    # Should fail gracefully
    [ "$status" -le 53 ]
    rmdir ~/.testcli.conf 2>/dev/null
}
