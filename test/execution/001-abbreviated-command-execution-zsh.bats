# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

setup_file() {
    echo "# setup_file" >&3
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="n" __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"
}
teardown_file() {
    echo "# teardown_file" >&3
    load '../_helpers/common-teardown'
    _common_teardown
}
setup() {
    load '../_test_helper/bats-support/load'
    load '../_test_helper/bats-assert/load'
    load '../_helpers/zsh-helpers'
}

@test "zsh: command is expanded correctly: e -> echo" {
    run _zsh_run e first-arg second-arg
	assert_success
	assert_line 'second-arg first-arg'
}

@test "zsh: command expansion: i w f m -> install war from maven" {
    # Under zsh direct execution, abbreviation expansion works
    run _zsh_run i w f m
    # The command should expand but execution fails because the script doesn't exist
    assert_failure
    assert_line --partial 'install war from maven'
}
