# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:fish
#
# Tests multiple CLI namespace isolation under fish

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    # Create a second CLI config
    cat > ~/.testcli2.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
greet: echo "hello from cli2"
CONF
}
teardown_file(){
    load '../_helpers/test-setup'
    _test_cleanup
    rm -f ~/.testcli2.conf
}
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: config file isolation between CLIs" {
    # testcli should use ~/.testcli.conf, not ~/.testcli2.conf
    run _fish_run echo first second third
    assert_success
    assert_output "second first third"
}

@test "fish: second CLI has its own commands" {
    # Create a testcli2 wrapper
    cat > ./testcli2 <<'WRAPPER'
#!/usr/bin/env fish
set -g __CLI_PROGNAME testcli2
set -g __cli_wrapper_argv $argv
source (path dirname (status filename))/audogombleed.fish
WRAPPER
    chmod +x ./testcli2
    run fish ./testcli2 greet
    assert_success
    assert_output "hello from cli2"
    rm -f ./testcli2
}
