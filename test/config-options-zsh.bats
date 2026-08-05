# vim:et:ts=4:sw=4

#
#	Tests configuration options under zsh
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

@test "zsh: executes command" {
    run _zsh_run echo first second
    assert_success
    assert_output "second first"
}

@test "zsh: propagates exit code" {
    run _zsh_run return2
    assert_failure 2
}
