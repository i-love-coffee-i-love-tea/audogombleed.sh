# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish

#
# Tests scoped &function loading: only relevant &functions are called (fish)
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    # Create a temp file for tracking calls
    export _TEST_CALL_LOG=$(mktemp)
    # inject test functions that track calls via file
    sed '/^\[commands\]/i \
[env.fish]\
function track_alpha\
    echo "alpha" >> "$_TEST_CALL_LOG"\
    echo "a1 a2"\
end\
function track_beta\
    echo "beta" >> "$_TEST_CALL_LOG"\
    echo "b1 b2"\
end\
function track_gamma\
    echo "gamma" >> "$_TEST_CALL_LOG"\
    echo "c1 c2"\
end\
' ~/.testcli.conf > ~/.testcli.conf.tmp && mv ~/.testcli.conf.tmp ~/.testcli.conf
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
    load '../_helpers/test-setup'
    _test_cleanup
    rm -f "$_TEST_CALL_LOG"
}
setup() {
    load '../_helpers/test-setup'
    _test_load_fish
    # Clear the log before each test
    > "$_TEST_CALL_LOG"
}

@test "fish: scoped &function loading calls only relevant &function" {
    # Complete alpha-cmd - should only call track_alpha
    run _fish_eval '_cli_complete_command 2 alpha-cmd'
    assert_line "a1"
    assert_line "a2"

    # Verify only track_alpha was called
    [ "$(grep -c 'alpha' "$_TEST_CALL_LOG")" = "1" ]
    [ "$(grep -c 'beta' "$_TEST_CALL_LOG")" = "0" ]
    [ "$(grep -c 'gamma' "$_TEST_CALL_LOG")" = "0" ]
}

@test "fish: scoped &function loading calls different function for different command" {
    # Complete beta-cmd - should only call track_beta
    run _fish_eval '_cli_complete_command 2 beta-cmd'
    assert_line "b1"
    assert_line "b2"

    # Verify only track_beta was called
    [ "$(grep -c 'alpha' "$_TEST_CALL_LOG")" = "0" ]
    [ "$(grep -c 'beta' "$_TEST_CALL_LOG")" = "1" ]
    [ "$(grep -c 'gamma' "$_TEST_CALL_LOG")" = "0" ]
}
