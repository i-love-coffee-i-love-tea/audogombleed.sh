# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-062
@test "zsh: output=command_names finds expected number of commands" {
    run _zsh_run --cli-run-awk-command output=command_names
	assert_equal "23" "${#lines[@]}"
	assert_line "install war from maven"
}

# bats test_tags=id:zsh-063
@test "zsh: output=commands finds expected number of commands" {
    run _zsh_run --cli-run-awk-command output=commands
	assert_success
	assert_equal "23" "${#lines[@]}"
	assert_line "install war from maven        , list,  ~/bin/install-maven-war.sh"
}

# bats test_tags=id:zsh-064
@test "zsh: command_filter with regex metacharacter matches literally" {
	run _zsh_run --cli-run-awk-command output=command_names command_filter="ech."
	assert_success
	assert_equal "${#lines[@]}" "0"
}
