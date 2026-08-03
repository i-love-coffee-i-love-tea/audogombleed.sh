# vim:et:ts=4:sw=4

#
#	Tests configuration options
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

# subprocess mode

@test "subprocess executes command" {
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_SUBPROCESS '"y"'
    source ./testcli
    run ./testcli echo first second
    assert_success
    assert_output "second first"
}

@test "subprocess propagates exit code" {
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_SUBPROCESS '"y"'
    source ./testcli
    run ./testcli return2
    assert_failure 2
}

@test "subprocess isolates shell state" {
    load 'common-setup'
    # add a cd command to the config
    echo 'cd-test: cd /tmp' >> ~/.testcli.conf
    _set_option __CLI_CFG_EXEC_SUBPROCESS '"y"'
    source ./testcli
    local before_pwd="$PWD"
    run ./testcli cd-test
    assert_success
    assert_equal "$PWD" "$before_pwd"
}

@test "current-shell mode executes and retains side effects" {
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_SUBPROCESS '"n"'
    source ./testcli
    run ./testcli echo first second
    assert_success
    assert_output "second first"
}
