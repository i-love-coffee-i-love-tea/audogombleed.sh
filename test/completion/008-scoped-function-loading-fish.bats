# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests scoped &function loading under fish

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    export _TEST_CALL_LOG=$(mktemp)
    # Append test commands that use tracked functions
    cat >> ~/.testcli.conf <<'CMDS'
alpha-cmd
    &track_alpha: echo \0
beta-cmd
    &track_beta: echo \0
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
    > "$_TEST_CALL_LOG"
}

@test "fish: scoped &function loading calls only relevant &function" {
    run _fish_eval '_cli_complete_command 2 alpha-cmd'
    assert_success
}

@test "fish: scoped &function loading calls different function for different command" {
    run _fish_eval '_cli_complete_command 2 beta-cmd'
    assert_success
}
