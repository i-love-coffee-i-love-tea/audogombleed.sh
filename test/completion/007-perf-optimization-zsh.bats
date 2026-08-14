# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh

#
# Tests for performance optimizations — behavioral correctness (zsh)
# Each test exercises a specific code path that is being optimized.
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

# Step 1: word-removal loop in _cli_is_command_complete

# bats test_tags=id:zsh-054
@test "zsh: hierarchical 3-word command completes correctly (exercises word-stripping)" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    run test_completion_zsh 4 "testcli" "install" "jar" ""
    assert_line "from"
}

# bats test_tags=id:zsh-055
@test "zsh: incomplete 2-word prefix completes to subcommands" {
    load '../_helpers/auto-completion-mock-setup-zsh'
    run test_completion_zsh 3 "testcli" "install" ""
    assert_line "jar"
    assert_line "war"
}
