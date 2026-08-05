# vim:et:ts=4:sw=4

#
# Tests for sourcing, completion registration, and shell detection (bash)
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

@test "bash: sourcing registers _cli_execute function" {
    run bash -c "source ./testcli && type _cli_execute"
    assert_success
    assert_line --partial "_cli_execute is a function"
}

@test "bash: sourcing registers completions" {
    run bash -c "source ./testcli && complete -p testcli"
    assert_success
    assert_line --partial "complete -F _cli_complete_ testcli"
}

@test "bash: direct execution shows usage message" {
    run ./audogombleed.sh
    assert_failure
    assert_line "This script is not intended to be called directly."
}

@test "bash: executes command with arguments" {
    run ./testcli echo first second
    assert_success
    assert_line "second first"
}

@test "bash: shell detection returns true" {
    run bash -c "source ./testcli && _cli_shell_is_bash && echo 'bash detected'"
    assert_success
    assert_line "bash detected"
}

@test "bash: _cli_complete_ function exists" {
    run bash -c "source ./testcli && type _cli_complete_"
    assert_success
    assert_line --partial "_cli_complete_ is a function"
}

@test "bash: _cli_execute function exists" {
    run bash -c "source ./testcli && type _cli_execute"
    assert_success
    assert_line --partial "_cli_execute is a function"
}
