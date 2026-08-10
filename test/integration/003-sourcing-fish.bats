# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:fish
#
# Tests for sourcing, completion registration, and shell detection (fish)

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: wrapper sources without error" {
    run fish -c 'source ./testcli; echo "ok"'
    assert_success
    assert_output "ok"
}

@test "fish: _cli_execute function exists after sourcing" {
    run fish -c 'source ./testcli; functions -q _cli_execute; and echo "exists"'
    assert_success
    assert_output "exists"
}

@test "fish: _awk function exists after sourcing" {
    run fish -c 'source ./testcli; functions -q _awk; and echo "exists"'
    assert_success
    assert_output "exists"
}

@test "fish: __CLI_PROGNAME is set after sourcing" {
    run fish -c 'source ./testcli; echo $__CLI_PROGNAME'
    assert_success
    assert_output "testcli"
}

@test "fish: __CLI_CONFIG_FILE is set after sourcing" {
    run fish -c 'source ./testcli; echo $__CLI_CONFIG_FILE'
    assert_success
    assert_output "$HOME/.testcli.conf"
}
