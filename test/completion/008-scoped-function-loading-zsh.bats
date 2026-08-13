# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh

#
# Tests scoped &function loading: only relevant &functions are called
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init __CLI_CFG_EXEC_SILENT="y"
    export _TEST_CALL_LOG=$(mktemp)
}
teardown_file() {
    load '../_helpers/test-setup'
    _test_cleanup
    rm -f "$_TEST_CALL_LOG"
}
setup() {
teardown() { load '../_helpers/test-setup'; _test_teardown; }
    load '../_helpers/test-setup'
    _test_load_zsh
    # Clear the log before each test
    > "$_TEST_CALL_LOG"
}

# bats test_tags=id:zsh-164
@test "zsh: scoped &function loading calls only relevant &function" {
    load '../_helpers/auto-completion-mock-setup'

    # Complete alpha-cmd - should only call track_alpha
    result="$(test_completion 2 "testcli" "alpha-cmd")"
    assert_equal "$result" 'a1 a2'

    # Verify only track_alpha was called
    assert_equal "$(grep -c 'alpha' "$_TEST_CALL_LOG")" "1"
    assert_equal "$(grep -c 'beta' "$_TEST_CALL_LOG")" "0"
    assert_equal "$(grep -c 'gamma' "$_TEST_CALL_LOG")" "0"
}

# bats test_tags=id:zsh-165
@test "zsh: scoped &function loading calls different function for different command" {
    load '../_helpers/auto-completion-mock-setup'

    # Complete beta-cmd - should only call track_beta
    result="$(test_completion 2 "testcli" "beta-cmd")"
    assert_equal "$result" 'b1 b2'

    # Verify only track_beta was called
    assert_equal "$(grep -c 'alpha' "$_TEST_CALL_LOG")" "0"
    assert_equal "$(grep -c 'beta' "$_TEST_CALL_LOG")" "1"
    assert_equal "$(grep -c 'gamma' "$_TEST_CALL_LOG")" "0"
}
