# vim:et:ts=4:sw=4

#
# Tests -b/--batch mode (zsh)
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

@test "zsh: batch mode executes command successfully" {
    run _zsh_run -b echo first second
    assert_success
    assert_output "second first"
}

@test "zsh: --batch long flag works same as -b" {
    run _zsh_run --batch echo first second
    assert_success
    assert_output "second first"
}

@test "zsh: batch mode returns correct exit code" {
    run _zsh_run -b return2
    assert_failure 2
}

@test "zsh: batch mode works with complex commands" {
    run _zsh_run -b install jar from file /some/file
    assert_success
    assert_output "/some/file"
}
