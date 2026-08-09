# vim:et:ts=4:sw=4

#
# Tests for performance optimizations — behavioral correctness
# Each test exercises a specific code path that is being optimized.
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

# Step 1: word-removal loop in _cli_is_command_complete
# Exercises the path where the command is not a prefix match and
# the function must strip the last word and retry.

@test "bash: hierarchical 3-word command completes correctly (exercises word-stripping)" {
    load 'auto-completion-mock-setup'
    result="$(test_completion 3 "testcli" "install" "jar" "")"
    assert_equal "$result" 'from'
}

@test "bash: incomplete 2-word prefix completes to subcommands" {
    load 'auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "install" "")"
    assert_equal "$result" 'jar war'
}
