# vim:et:ts=4:sw=4

#
# Tests for performance optimizations — behavioral correctness (zsh)
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

@test "zsh: hierarchical 3-word command completes correctly (exercises word-stripping)" {
    load 'auto-completion-mock-setup-zsh'
    run test_completion_zsh 4 "testcli" "install" "jar" ""
    assert_line "from"
}

@test "zsh: incomplete 2-word prefix completes to subcommands" {
    load 'auto-completion-mock-setup-zsh'
    run test_completion_zsh 3 "testcli" "install" ""
    assert_line "jar"
    assert_line "war"
}
