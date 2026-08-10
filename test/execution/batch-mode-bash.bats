# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
# Tests -b/--batch mode (bash)
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
}

# bats test_tags=id:bash-172
@test "bash: batch mode executes command successfully" {
    run ./testcli -b echo first second
    assert_success
    assert_output "second first"
}

# bats test_tags=id:bash-173
@test "bash: --batch long flag works same as -b" {
    run ./testcli --batch echo first second
    assert_success
    assert_output "second first"
}

# bats test_tags=id:bash-174
@test "bash: batch mode disables abbreviation expansion" {
    # In batch mode, abbreviation is disabled so 'e' won't expand to 'echo'
    run ./testcli -b e first second
    assert_failure 51
}

# bats test_tags=id:bash-175
@test "bash: batch mode returns correct exit code" {
    run ./testcli -b return2
    assert_failure 2
}

# bats test_tags=id:bash-176
@test "bash: batch mode works with complex commands" {
    run ./testcli -b install jar from file /some/file
    assert_success
    assert_output "/some/file"
}
