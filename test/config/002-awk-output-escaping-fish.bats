# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: AWK output escapes double quotes in arg description" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:STRING:arg "with" quotes
CONF
    run _fish_run --cli-run-awk-command output=commands command_filter="test-cmd"
    assert_success
    # The description should have escaped quotes so eval doesn't break
    assert_line 'set -g __CMD_ARG_DESC[1] "arg \"with\" quotes"'
}

@test "fish: AWK output escapes double quotes in arg value" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:list:value "with" quotes
CONF
    run _fish_run --cli-run-awk-command output=commands command_filter="test-cmd"
    assert_success
    # The value should have escaped quotes so eval doesn't break
    assert_line 'set -g __CMD_ARG_VALUE[1] "value \"with\" quotes"'
}

@test "fish: AWK output with quoted args is safe to eval" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo \1
    :arg:STRING:arg "with" quotes
CONF
    # Capture AWK output and eval it — should not break
    run _fish_eval 'set -l output (./testcli --cli-run-awk-command output=commands command_filter="test-cmd" | string collect); eval "$output"; echo $__CMD_ARG_DESC[1]'
    assert_success
    assert_output --partial 'arg "with" quotes'
}
