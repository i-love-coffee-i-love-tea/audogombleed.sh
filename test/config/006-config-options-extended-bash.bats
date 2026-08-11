# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash

#
# Tests extended configuration options (bash)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# CFG_EXEC_ALWAYS_RETURN_0

# bats test_tags=id:bash-099
@test "bash: ALWAYS_RETURN_0 returns 0 for failing command" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
    source ./testcli
    run ./testcli false
    assert_success
}

# bats test_tags=id:bash-100
@test "bash: ALWAYS_RETURN_0 returns 0 for exit code 2" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"y"'
    source ./testcli
    run ./testcli return2
    assert_success
}

# bats test_tags=id:bash-101
@test "bash: ALWAYS_RETURN_0=n preserves real exit code" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ALWAYS_RETURN_0 '"n"'
    source ./testcli
    run ./testcli return2
    assert_failure 2
}

# CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY
# Note: this option is enforced at completion time, not execution time.

# bats test_tags=id:bash-102
@test "bash: ARGS_ALLOW_COMPLETION_RESULTS_ONLY does not affect execution" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY '"y"'
    source ./testcli
    # The option only affects tab completion, not command execution
    run ./testcli list-argument static not-in-list
    assert_success
    assert_line "not-in-list"
}

# bats test_tags=id:bash-103
@test "bash: ARGS_ALLOW_COMPLETION_RESULTS_ONLY=n allows any value" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY '"n"'
    source ./testcli
    run ./testcli list-argument static not-in-list
    assert_success
    assert_line "not-in-list"
}

# CFG_LOG_LEVEL

# bats test_tags=id:bash-104
@test "bash: LOG_LEVEL=4 creates log file" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_LOG_LEVEL '4'
    source ./testcli
    run ./testcli echo first second
    assert_success
    local logfile
    logfile=$(ls /tmp/cli-*-bash.log 2>/dev/null | head -1)
    [ -n "$logfile" ]
    rm -f /tmp/cli-*-bash.log
}

# source directive in [env]

# bats test_tags=id:bash-105
@test "bash: source directive in env loads external script" {
    # Create an external script
    cat > /tmp/test-source-script.sh <<'EOF'
export TEST_SOURCE_VAR="hello from sourced script"
EOF
    # Create config with source directive in [env] section
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
source /tmp/test-source-script.sh

[commands]
echo: \0 \2 \1
    :arg1:list:first
    :arg2:list:second
test-source-cmd: echo $TEST_SOURCE_VAR
CONF
    run ./testcli test-source-cmd
    assert_success
    assert_line "hello from sourced script"
    rm -f /tmp/test-source-script.sh
}

# [env] section is optional

# bats test_tags=id:bash-106
@test "bash: config without [env] section works" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo "no-env"
CONF
    source ./testcli
    run ./testcli test-cmd
    assert_success
    assert_line "no-env"
}

# bats test_tags=id:bash-107
@test "bash: config with neither [env] nor anything else works" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
test-cmd: echo "bare-minimum"
CONF
    source ./testcli
    run ./testcli test-cmd
    assert_success
    assert_line "bare-minimum"
}
