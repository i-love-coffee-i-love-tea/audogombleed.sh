# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests CLI flags under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: --version flag shows version" {
    run _fish_run --version
    assert_success
    assert_output --partial "2."
}

@test "fish: --cli-print-awk-script flag prints AWK script" {
    run _fish_run --cli-print-awk-script
    assert_success
    # Should contain AWK code
    assert_output --partial "BEGIN"
}

@test "fish: --cli-run-awk-command flag runs AWK command" {
    run _fish_run --cli-run-awk-command output=command_names
    assert_success
    # Should return command names
    [ "${#lines[@]}" -gt 0 ]
}

@test "fish: --cli-print-env flag prints environment" {
    run _fish_run --cli-print-env
    assert_success
    [ "${#lines[@]}" -gt 0 ]
}
