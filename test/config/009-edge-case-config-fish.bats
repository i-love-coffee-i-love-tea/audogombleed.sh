# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests edge case configs under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: edge-case: random 500-byte config does not crash" {
    head -c 500 /dev/urandom | tr -d '\0' > ~/.testcli.conf
    run _fish_run test-cmd 2>&1
    [ "$status" -le 53 ]
}

@test "fish: edge-case: config with only special characters does not crash" {
    echo '!@#$%^&*(){}[]|\\:;<>?/~`' > ~/.testcli.conf
    run _fish_run test-cmd 2>&1
    [ "$status" -le 53 ]
}

@test "fish: edge-case: config with only colons does not crash" {
    printf ':::::\n:::::\n:::::\n' > ~/.testcli.conf
    run _fish_run test-cmd 2>&1
    [ "$status" -le 53 ]
}

@test "fish: edge-case: config with only pipes does not crash" {
    printf '|||||\n|||||\n|||||\n' > ~/.testcli.conf
    run _fish_run test-cmd 2>&1
    [ "$status" -le 53 ]
}

@test "fish: edge-case: config with [commands] appearing multiple times" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
cmd1: echo one
[commands]
cmd2: echo two
CONF
    run _fish_run cmd1 2>&1
    [ "$status" -le 53 ]
}

@test "fish: edge-case: config with [env] after [commands]" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo hello
[env]
__CLI_CFG_EXEC_SILENT="y"
CONF
    run _fish_run test-cmd 2>&1
    [ "$status" -le 53 ]
}

@test "fish: edge-case: config with no newline at end" {
    printf '[commands]\ntest-cmd: echo hello' > ~/.testcli.conf
    run _fish_run test-cmd
    assert_success
    assert_line "hello"
}

@test "fish: edge-case: config with only newlines" {
    printf '\n\n\n\n\n' > ~/.testcli.conf
    run _fish_run test-cmd 2>&1
    [ "$status" -le 53 ]
}

@test "fish: edge-case: config with tab-only indentation" {
    printf '[env]\n__CLI_CFG_EXEC_SILENT="y"\n[env.fish]\n[commands]\ntest-cmd: echo hello\n\t:arg:list:a|b\n' > ~/.testcli.conf
    run _fish_run test-cmd a
    assert_success
    assert_line "hello a"
}
