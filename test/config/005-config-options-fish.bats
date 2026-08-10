# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests config options under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: backslashes in config values are preserved" {
    cat > ~/.testcli.conf <<'CONF'
[env]
MY_PATH="C:\\Users\\test"
[env.fish]
[commands]
test-cmd: echo $MY_PATH
CONF
    run _fish_run test-cmd
    assert_success
}
