# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-092
@test "bash: AWK output escapes double quotes in arg description" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:STRING:arg "with" quotes
CONF
    source ./testcli
    run ./testcli --cli-run-awk-command output=commands command_filter="test-cmd"
    assert_success
    # The description should have escaped quotes so eval doesn't break
    assert_line '__CMD_ARG_DESC[0]="arg \"with\" quotes"'
}

# bats test_tags=id:bash-093
@test "bash: AWK output escapes double quotes in arg value" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:list:value "with" quotes
CONF
    source ./testcli
    run ./testcli --cli-run-awk-command output=commands command_filter="test-cmd"
    assert_success
    # The value should have escaped quotes so eval doesn't break
    assert_line '__CMD_ARG_VALUE[0]="value \"with\" quotes"'
}

# bats test_tags=id:bash-094
@test "bash: AWK output with quoted args is safe to eval" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:STRING:arg "with" quotes
CONF
    source ./testcli
    # Capture AWK output and eval it — should not break
    local output
    output="$(./testcli --cli-run-awk-command output=commands command_filter="test-cmd")"
    eval "$output"
    assert_equal "${__CMD_ARG_DESC[0]}" 'arg "with" quotes'
}
