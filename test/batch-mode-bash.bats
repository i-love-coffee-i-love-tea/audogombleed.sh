# vim:et:ts=4:sw=4

#
# Tests -b/--batch mode (bash)
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

@test "bash: batch mode executes command successfully" {
    run ./testcli -b echo first second
    assert_success
    assert_output "second first"
}

@test "bash: --batch long flag works same as -b" {
    run ./testcli --batch echo first second
    assert_success
    assert_output "second first"
}

@test "bash: batch mode disables abbreviation expansion" {
    # In batch mode, abbreviation is disabled so 'e' won't expand to 'echo'
    run ./testcli -b e first second
    assert_failure 51
}

@test "bash: batch mode returns correct exit code" {
    run ./testcli -b return2
    assert_failure 2
}

@test "bash: batch mode works with complex commands" {
    run ./testcli -b install jar from file /some/file
    assert_success
    assert_output "/some/file"
}
