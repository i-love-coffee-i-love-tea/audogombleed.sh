# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
# Tests command abbreviation expansion (zsh)
#
# Note: zsh direct execution (zsh ./testcli) has a known limitation where
# _cli_is_sourced loses the 'file' token in zsh_eval_context after sourcing.
# Abbreviation expansion that triggers _cli_exit_if_not_sourced will call exit
# instead of return. This is documented in docs/10-faq.md.
# Tests that need abbreviation should use full command names.

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n" __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-101
@test "zsh: full command names work without abbreviation" {
    run _zsh_run echo first second
    assert_success
    assert_line "second first"
}

# bats test_tags=id:zsh-102
@test "zsh: unrecognized command returns exit 51" {
    run _zsh_run nonexistent
    assert_failure 51
}

# bats test_tags=id:zsh-103
@test "zsh: batch mode disables command execution" {
    # In batch mode with SILENT=n, unrecognized commands fail
    run _zsh_run -b nonexistent
    assert_failure 51
}
