# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh

#
# Tests scoped &function loading: only relevant &functions are called
#

setup_file() {
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"

    # Create a temp file for tracking calls
    export _TEST_CALL_LOG=$(mktemp)

    # inject test functions that track calls via file
    sed '/^\[commands\]/i \
_TEST_CALL_LOG='"$_TEST_CALL_LOG"'\
track_alpha() { echo "alpha" >> "$_TEST_CALL_LOG"; echo "a1 a2"; }\
track_beta() { echo "beta" >> "$_TEST_CALL_LOG"; echo "b1 b2"; }\
track_gamma() { echo "gamma" >> "$_TEST_CALL_LOG"; echo "c1 c2"; }' ~/.testcli.conf > ~/.testcli.conf.tmp && mv ~/.testcli.conf.tmp ~/.testcli.conf

    # append test commands to [commands] section
    cat >> ~/.testcli.conf <<'CMDS'

alpha-cmd
    &track_alpha: echo \0
beta-cmd
    &track_beta: echo \0
gamma-cmd
    &track_gamma: echo \0
CMDS
}
teardown_file() {
    rm -f "$_TEST_CALL_LOG"
    load '../_helpers/common-teardown'
    _common_teardown
}
setup() {
    load '../_test_helper/bats-support/load'
    load '../_test_helper/bats-assert/load'
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
