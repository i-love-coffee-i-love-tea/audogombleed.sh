# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:bash

#
# Tests for performance optimizations — behavioral correctness
# Each test exercises a specific code path that is being optimized.
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

# Step 1: word-removal loop in _cli_is_command_complete
# Exercises the path where the command is not a prefix match and
# the function must strip the last word and retry.

# bats test_tags=id:bash-072
@test "bash: hierarchical 3-word command completes correctly (exercises word-stripping)" {
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 3 "testcli" "install" "jar" "")"
    assert_equal "$result" 'from'
}

# bats test_tags=id:bash-073
@test "bash: incomplete 2-word prefix completes to subcommands" {
    load '../_helpers/auto-completion-mock-setup'
    result="$(test_completion 2 "testcli" "install" "")"
    assert_equal "$result" 'jar war'
}
