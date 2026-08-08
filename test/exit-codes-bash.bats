# vim:et:ts=4:sw=4

#
#	Tests exit codes 49, 51, 52, 53
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

@test "exit code 49: script called with wrong name" {
    # When audogombleed.sh is called directly (not via symlink), it should exit 49
    run ./audogombleed.sh
    assert_failure 49
    assert_line "This script is not intended to be called directly."
}

@test "exit code 50: no command supplied" {
    # When no command is provided, should exit 50
    run env __CLI_testcli_CFG_EXEC_SILENT="n" ./testcli
    assert_failure 50
}

@test "exit code 51: unrecognized command" {
    # When command doesn't exist, should exit 51
    run ./testcli nonexistent-command
    assert_failure 51
}

@test "exit code 51: abbreviated command expansion fails" {
    # When abbreviation is ambiguous, should exit 51
    # First add commands that could be ambiguous
    echo 'ambiguous-test-1: echo test1' >> ~/.testcli.conf
    echo 'ambiguous-test-2: echo test2' >> ~/.testcli.conf
    
    source ./testcli
    
    # Try to use an ambiguous abbreviation
    run ./testcli amb
    assert_failure 51
}

@test "exit code 52: more placeholders than args" {
    # When command expression has more placeholders than args provided,
    # exit code 52 should be returned.
    echo 'test-placeholders: echo \1 \2 \3' >> ~/.testcli.conf
    echo '    :arg1:list:one|two' >> ~/.testcli.conf
    echo '    :arg2:list:alpha|beta' >> ~/.testcli.conf
    echo '    :arg3:list:x|y' >> ~/.testcli.conf

    source ./testcli

    # Supply only 2 args when 3 placeholders exist
    run ./testcli test-placeholders one alpha
    assert_failure 52
}

@test "exit code 53: command with missing required args" {
    # When required args are missing, exit code 53 should be returned.
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_SILENT '"n"'
    source ./testcli
    run ./testcli echo
    assert_failure 53
}

@test "exit code 0: successful command execution" {
    run ./testcli echo first second third
    assert_success
    assert_line "second first third"
}

@test "exit code matches command exit status" {
    # The 'false' command should return non-zero
    run ./testcli false
    assert_failure
    
    # The 'return2' command should return 2
    run ./testcli return2
    assert_failure 2
}
