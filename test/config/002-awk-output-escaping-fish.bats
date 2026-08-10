# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests AWK output escaping under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: AWK output escapes double quotes in arg description" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:STRING:arg "with" quotes
CONF
    run _fish_run --cli-run-awk-command output=commands command_filter="test-cmd"
    assert_success
}

@test "fish: AWK output escapes double quotes in arg value" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:list:value "with" quotes
CONF
    run _fish_run --cli-run-awk-command output=commands command_filter="test-cmd"
    assert_success
}
