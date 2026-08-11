# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish

#
# Tests for performance optimizations — behavioral correctness (fish)
# Each test exercises a specific code path that is being optimized.
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# Step 1: word-removal loop in _cli_is_command_complete
# Exercises the path where the command is not a prefix match and
# the function must strip the last word and retry.

@test "fish: hierarchical 3-word command completes correctly (exercises word-stripping)" {
    run _fish_eval '_cli_complete_command 4 install jar from'
    assert_line "file"
    assert_line "maven"
}

@test "fish: incomplete 2-word prefix completes to subcommands" {
    run _fish_eval '_cli_complete_command 2 install'
    assert_line "jar"
    assert_line "war"
}
