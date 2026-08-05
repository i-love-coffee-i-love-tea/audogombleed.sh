# vim:et:ts=4:sw=4

#
# Tests CLI flags: --version, --cli-print-awk-script, --cli-run-awk-command, --cli-print-env (bash)
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
}

@test "bash: --version prints version string" {
    run ./testcli --version
    assert_success
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "bash: --cli-print-awk-script prints the AWK script" {
    run ./testcli --cli-print-awk-script
    assert_success
    assert_line '#!/usr/bin/awk -f'
    assert_line 'BEGIN {'
    assert_line 'END {'
}

@test "bash: --cli-run-awk-command output=command_names lists commands" {
    run ./testcli --cli-run-awk-command output=command_names
    assert_success
    assert_line "echo"
    assert_line "install war from maven"
}

@test "bash: --cli-run-awk-command output=command_names with filter" {
    run ./testcli --cli-run-awk-command output=command_names command_filter="install"
    assert_success
    assert_line "install jar from file"
    assert_line "install jar from maven"
    assert_line "install war from file"
    assert_line "install war from maven"
}

@test "bash: --cli-run-awk-command output=env prints env section" {
    run ./testcli --cli-run-awk-command output=env
    assert_success
    assert_line --partial "__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS"
}

@test "bash: --cli-print-env prints env section" {
    run ./testcli --cli-print-env
    assert_success
    assert_line --partial "__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS"
}
