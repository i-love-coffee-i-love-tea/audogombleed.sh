# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish

#
# Tests extended configuration options (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# CFG_EXEC_ALWAYS_RETURN_0

@test "fish: ALWAYS_RETURN_0 returns 0 for failing command" {
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
    run _fish_run false
    assert_success
}

@test "fish: ALWAYS_RETURN_0 returns 0 for exit code 2" {
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
    run _fish_run return2
    assert_success
}

@test "fish: ALWAYS_RETURN_0=n preserves real exit code" {
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"n"'
    run _fish_run return2
    assert_failure 2
}

# CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY
# Note: this option is enforced at completion time, not execution time.

@test "fish: ARGS_ALLOW_COMPLETION_RESULTS_ONLY does not affect execution" {
    _set_option __CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY '"y"'
    # The option only affects tab completion, not command execution
    run _fish_run list-argument static not-in-list
    assert_success
    assert_line "not-in-list"
}

@test "fish: ARGS_ALLOW_COMPLETION_RESULTS_ONLY=n allows any value" {
    _set_option __CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY '"n"'
    run _fish_run list-argument static not-in-list
    assert_success
    assert_line "not-in-list"
}

# CFG_LOG_LEVEL

@test "fish: LOG_LEVEL=4 creates log file" {
    _set_option __CLI_CFG_LOG_LEVEL '4'
    run _fish_run echo first second
    assert_success
    local logfile
    logfile=$(ls /tmp/cli-*-fish.log 2>/dev/null | head -1)
    assert_not_empty "$logfile"
    rm -f /tmp/cli-*-fish.log
}

# source directive in [env]

@test "fish: source directive in env loads external script" {
    # Create an external script
    cat > /tmp/test-source-script-fish.sh <<'EOF'
export TEST_SOURCE_VAR_FISH="hello from sourced script"
EOF
    # Create config with source directive in [env] section
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
source /tmp/test-source-script-fish.sh

[commands]
echo: \0 \2 \1
    :arg1:list:first
    :arg2:list:second
test-source-cmd-fish: echo $TEST_SOURCE_VAR_FISH
CONF
    run _fish_run test-source-cmd-fish
    assert_success
    assert_line "hello from sourced script"
    rm -f /tmp/test-source-script-fish.sh
}

# [env] section is optional

@test "fish: config without [env] section works" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo "no-env"
CONF
    run _fish_run test-cmd
    assert_success
    assert_line "no-env"
}

@test "fish: config with neither [env] nor anything else works" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo "bare-minimum"
CONF
    run _fish_run test-cmd
    assert_success
    assert_line "bare-minimum"
}
