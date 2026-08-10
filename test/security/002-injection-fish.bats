# vim:et:ts=4:sw=4
# bats file_tags=category:security, shell:fish
#
# Injection tests under fish -- verify malicious input is handled safely

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: command substitution in command name does not execute" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-$(echo injected)-cmd: echo "safe"
CONF
    run fish -c 'source ./testcli; _cli_execute "test-$(echo injected)-cmd" 2>&1'
    assert_failure
    refute_output --partial "safe"
}

@test "fish: semicolon in list value is preserved literally" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
greet: echo "hello"
    :msg:list:hello;echo injected|world
CONF
    run _fish_run --cli-run-awk-command output=commands command_filter="greet"
    assert_success
    assert_line --partial 'hello;echo injected'
}

@test "fish: dollar-sign in argument value is literal" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-cmd: echo \1
    :arg:list:$(whoami)|safe
CONF
    run _fish_run --cli-run-awk-command output=commands command_filter="test-cmd"
    assert_success
    assert_line --partial '$(whoami)'
}

@test "fish: extremely long command name does not crash parser" {
    local long_name
    long_name=$(printf 'a%.0s' {1..10000})
    cat > ~/.testcli.conf <<CONF
[env.fish]
[commands]
$long_name: echo "long"
CONF
    run _fish_run "$long_name"
    [ "$status" -le 53 ]
}

@test "fish: extremely long argument value does not crash parser" {
    local long_value
    long_value=$(printf 'x%.0s' {1..10000})
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-cmd: echo \1
    :arg:STRING
CONF
    run _fish_run test-cmd "$long_value"
    [ "$status" -le 53 ]
}

@test "fish: config with 1000 commands does not crash parser" {
    {
        echo "[env.fish]"
        echo "[commands]"
        for i in $(seq 1 1000); do
            echo "cmd-$i: echo $i"
        done
    } > ~/.testcli.conf
    run _fish_run cmd-500
    assert_success
    assert_output --partial "500"
}
