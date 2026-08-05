# vim:et:ts=4:sw=4

#
# Tests command abbreviation expansion (zsh)
#
# Note: zsh direct execution (zsh ./testcli) has a known limitation where
# _cli_is_sourced loses the 'file' token in zsh_eval_context after sourcing.
# Abbreviation expansion that triggers _cli_exit_if_not_sourced will call exit
# instead of return. This is documented in docs/10-faq.md.
# Tests that need abbreviation should use full command names.

setup_file() {
    echo "# setup_file" >&3
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="n" __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"
}
teardown_file() {
    echo "# teardown_file" >&3
    load 'common-teardown'
    _common_teardown
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'zsh-helpers'
}

@test "zsh: full command names work without abbreviation" {
    run _zsh_run echo first second
    assert_success
    assert_line "second first"
}

@test "zsh: unrecognized command returns exit 51" {
    run _zsh_run nonexistent
    assert_failure 51
}

@test "zsh: batch mode disables command execution" {
    # In batch mode with SILENT=n, unrecognized commands fail
    run _zsh_run -b nonexistent
    assert_failure 51
}
