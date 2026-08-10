# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests performance optimization behavioral correctness under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: hierarchical 3-word command completes correctly (exercises word-stripping)" {
    run _fish_eval '_cli_complete_command 3 install jar'
    assert_success
    assert_line "from"
}

@test "fish: incomplete 2-word prefix completes to subcommands" {
    run _fish_eval '_cli_complete_command 2 install'
    assert_success
    assert_line "jar"
    assert_line "war"
}
