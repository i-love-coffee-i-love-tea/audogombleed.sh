# vim:et:ts=4:sw=4

#
# Tests extended configuration options (zsh)
#

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load 'common-teardown'
    _common_teardown
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'zsh-helpers'
}

# CFG_EXEC_ALWAYS_RETURN_0

@test "zsh: ALWAYS_RETURN_0 returns 0 for failing command" {
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
    run _zsh_run false
    assert_success
}

@test "zsh: ALWAYS_RETURN_0 returns 0 for exit code 2" {
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
    run _zsh_run return2
    assert_success
}

@test "zsh: ALWAYS_RETURN_0=n preserves real exit code" {
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"n"'
    run _zsh_run return2
    assert_failure 2
}

# CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY

@test "zsh: ARGS_ALLOW_COMPLETION_RESULTS_ONLY does not affect execution" {
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY '"y"'
    run _zsh_run list-argument static not-in-list
    assert_success
    assert_line "not-in-list"
}

@test "zsh: ARGS_ALLOW_COMPLETION_RESULTS_ONLY=n allows any value" {
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY '"n"'
    run _zsh_run list-argument static not-in-list
    assert_success
    assert_line "not-in-list"
}

# CFG_LOG_LEVEL

@test "zsh: LOG_LEVEL=4 creates log file" {
    load 'common-setup'
    _set_option __CLI_CFG_LOG_LEVEL '4'
    run _zsh_run echo first second
    assert_success
    local logfile
    logfile=$(ls /tmp/cli-*-zsh.log 2>/dev/null | head -1)
    [ -n "$logfile" ]
    rm -f /tmp/cli-*-zsh.log
}

# source directive in [env]

@test "zsh: source directive in env loads external script" {
    cat > /tmp/test-source-script-zsh.sh <<'EOF'
export TEST_SOURCE_VAR_ZSH="hello from sourced script"
EOF
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
source /tmp/test-source-script-zsh.sh

[commands]
echo: \0 \2 \1
    :arg1:list:first
    :arg2:list:second
test-source-cmd-zsh: echo $TEST_SOURCE_VAR_ZSH
CONF
    run _zsh_run test-source-cmd-zsh
    assert_success
    assert_line "hello from sourced script"
    rm -f /tmp/test-source-script-zsh.sh
}
