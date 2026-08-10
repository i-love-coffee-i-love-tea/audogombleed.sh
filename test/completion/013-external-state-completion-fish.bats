# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests that external state changes are reflected in completions under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: variable change in config is reflected in completions" {
    # Change the variable value in config
    sed -i 's/__VAR_EXPANSION_WORDS="first \\/__VAR_EXPANSION_WORDS="newvalue \\/' ~/.testcli.conf
    run _fish_eval '_cli_complete_command 2 var-expansion'
    assert_success
    assert_line --partial "newvalue"
}

@test "fish: function change in config is reflected in completions" {
    # Change the function in [env.fish]
    sed -i 's/echo "thievery"/echo "updated"/' ~/.testcli.conf
    run _fish_eval '_cli_complete_command 2 function-expansion'
    assert_success
    assert_line --partial "updated"
}
