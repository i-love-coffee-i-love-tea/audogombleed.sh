# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-064
@test "zsh: AWK output escapes double quotes in arg description" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:STRING:arg "with" quotes
CONF
    source ./testcli
    run ./testcli --cli-run-awk-command output=commands command_filter="test-cmd"
    assert_success
    assert_line '__CMD_ARG_DESC[0]="arg \"with\" quotes"'
}

# bats test_tags=id:zsh-065
@test "zsh: AWK output escapes double quotes in arg value" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:list:value "with" quotes
CONF
    source ./testcli
    run ./testcli --cli-run-awk-command output=commands command_filter="test-cmd"
    assert_success
    assert_line '__CMD_ARG_VALUE[0]="value \"with\" quotes"'
}

# bats test_tags=id:zsh-066
@test "zsh: AWK output with quoted args is safe to eval" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:STRING:arg "with" quotes
CONF
    source ./testcli
    local output
    output="$(./testcli --cli-run-awk-command output=commands command_filter="test-cmd")"
    eval "$output"
    assert_equal "${__CMD_ARG_DESC[0]}" 'arg "with" quotes'
}
