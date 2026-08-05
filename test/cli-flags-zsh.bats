# vim:et:ts=4:sw=4

#
# Tests CLI flags: --version, --cli-print-awk-script, --cli-run-awk-command, --cli-print-env (zsh)
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

@test "zsh: --version prints version string" {
    run _zsh_run --version
    assert_success
    assert_output "1.2.0"
}

@test "zsh: --cli-print-awk-script prints the AWK script" {
    run _zsh_run --cli-print-awk-script
    assert_success
    assert_line '#!/usr/bin/awk -f'
    assert_line 'BEGIN {'
    assert_line 'END {'
}

@test "zsh: --cli-run-awk-command output=command_names lists commands" {
    run _zsh_run --cli-run-awk-command output=command_names
    assert_success
    assert_line "echo"
    assert_line "install war from maven"
}

@test "zsh: --cli-run-awk-command output=command_names with filter" {
    run _zsh_run --cli-run-awk-command output=command_names command_filter="install"
    assert_success
    assert_line "install jar from file"
    assert_line "install jar from maven"
    assert_line "install war from file"
    assert_line "install war from maven"
}

@test "zsh: --cli-print-env prints env section" {
    run _zsh_run --cli-print-env
    assert_success
    assert_line --partial "__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS"
}
