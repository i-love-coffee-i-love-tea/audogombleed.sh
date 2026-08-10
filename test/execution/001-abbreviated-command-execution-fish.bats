# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish
#
# Tests abbreviated command execution under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="n" __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: command is expanded correctly: e -> echo" {
    run _fish_run e first-arg second-arg
	assert_success
	assert_line --partial 'Executing command "echo"'
	assert_line "second-arg first-arg"
}

@test "fish: command is expanded correctly: i w f m -> install war from maven" {
    run _fish_run i w f m coord123
	assert_line --partial 'Executing command "install war from maven"'
}
