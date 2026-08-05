# vim:et:ts=4:sw=4

#
#	Tests exit codes under zsh
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

@test "zsh: exit code 49 - script called with wrong name" {
    run zsh ./audogombleed.sh
    assert_failure 49
}

@test "zsh: exit code 50 - no command supplied" {
    run _zsh_run
    assert_failure 50
}

@test "zsh: exit code 51 - unrecognized command" {
    run _zsh_run nonexistent-command
    assert_failure 51
}

@test "zsh: exit code 0 - successful command execution" {
    run _zsh_run echo first second third
    assert_success
    assert_output "second first third"
}

@test "zsh: exit code matches command exit status" {
    run _zsh_run false
    assert_failure

    run _zsh_run return2
    assert_failure 2
}
