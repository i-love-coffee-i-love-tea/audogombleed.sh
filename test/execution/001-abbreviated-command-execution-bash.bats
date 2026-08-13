# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n" __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

@test "command is expanded correctly: e -> echo" {
    run ./testcli e first-arg second-arg
	assert_success
	assert_line --index 0 --partial 'Executing command "echo" --> echo second-arg first-arg'
	assert_line --index 1 			'second-arg first-arg'
}

@test "command is expanded correctly: i w f m -> install war from maven, execution of missing program fails" {
    # fixed warning about minimum required version 1.5.0 for 'run' command with parameters
	bats_require_minimum_version 1.5.0
	# -127 disables a bats warning when the command it tests fails with exit code 127
    run -127 ./testcli i w f m coord123

	assert_failure 127
	assert_line --index 0 --partial 'Executing command "install war from maven" --> ~/bin/install-maven-war.sh'
	assert_line --index 1 --partial	'bin/install-maven-war.sh: No such file or directory'
}



