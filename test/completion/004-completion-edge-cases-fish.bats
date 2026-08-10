# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests completion edge cases under fish
# Covers: multi-word command completion, arg completion after complete command

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# ===================================================================
# Multi-word command completion
# ===================================================================

@test "fish: completion produces results for multi-word commands" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy
	staging: echo deploying-staging
	production: echo deploying-production
CONF
    run _fish_eval '_cli_complete_command 2 deploy'
    assert_success
    assert_line --partial "staging"
    assert_line --partial "production"
}

# ===================================================================
# Completion after complete multi-word command
# ===================================================================

@test "fish: completion after complete multi-word command shows args" {
    cat > ~/.testcli.conf <<'CONF'
[commands]
deploy
	staging: echo
		:env:list:prod|dev|test
	production: echo
		:env:list:prod|dev|test
CONF
    run _fish_eval '_cli_complete_arg 0 "" deploy staging'
    assert_success
    assert_line --partial "prod"
    assert_line --partial "dev"
    assert_line --partial "test"
}
