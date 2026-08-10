# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests error handling under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: CLI name detection from wrapper" {
    run fish -c 'source ./testcli; echo $__CLI_PROGNAME'
    assert_success
    assert_output "testcli"
}

@test "fish: source errors are non-fatal" {
    cat > ~/.testcli.conf <<'CONF'
[env]
source /nonexistent/file/path.sh
[env.fish]
[commands]
test-cmd: echo "works"
CONF
    run _fish_run test-cmd
    assert_success
}

@test "fish: empty config file" {
    echo "" > ~/.testcli.conf
    run _fish_run test-cmd
    assert_failure
}

@test "fish: config with only env section" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
CONF
    run _fish_run test-cmd
    assert_failure
}
