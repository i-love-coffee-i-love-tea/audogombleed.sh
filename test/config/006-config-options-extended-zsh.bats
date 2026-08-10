# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh

#
# Tests extended configuration options (zsh)
#

setup_file() {
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load '../_helpers/common-teardown'
    _common_teardown
}
setup() {
    load '../_test_helper/bats-support/load'
    load '../_test_helper/bats-assert/load'
    load '../_helpers/zsh-helpers'
}

# CFG_EXEC_ALWAYS_RETURN_0

# bats test_tags=id:zsh-071
@test "zsh: ALWAYS_RETURN_0 returns 0 for failing command" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
    run _zsh_run false
    assert_success
}

# bats test_tags=id:zsh-072
@test "zsh: ALWAYS_RETURN_0 returns 0 for exit code 2" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
    run _zsh_run return2
    assert_success
}

# bats test_tags=id:zsh-073
@test "zsh: ALWAYS_RETURN_0=n preserves real exit code" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"n"'
    run _zsh_run return2
    assert_failure 2
}

# CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY

# bats test_tags=id:zsh-074
@test "zsh: ARGS_ALLOW_COMPLETION_RESULTS_ONLY does not affect execution" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY '"y"'
    run _zsh_run list-argument static not-in-list
    assert_success
    assert_line "not-in-list"
}

# bats test_tags=id:zsh-075
@test "zsh: ARGS_ALLOW_COMPLETION_RESULTS_ONLY=n allows any value" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY '"n"'
    run _zsh_run list-argument static not-in-list
    assert_success
    assert_line "not-in-list"
}

# CFG_LOG_LEVEL

# bats test_tags=id:zsh-076
@test "zsh: LOG_LEVEL=4 creates log file" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_LOG_LEVEL '4'
    run _zsh_run echo first second
    assert_success
    local logfile
    logfile=$(ls /tmp/cli-*-zsh.log 2>/dev/null | head -1)
    [ -n "$logfile" ]
    rm -f /tmp/cli-*-zsh.log
}

# source directive in [env]

# bats test_tags=id:zsh-077
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
