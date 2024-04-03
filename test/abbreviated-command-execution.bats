setup_file() {
  	echo "# setup_file" >&3
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="n" __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"
}
teardown_file() {
  	echo "# teardown_file" >&3
    load 'common-teardown'
    _common_teardown
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
}

@test "command is expanded correctly: e -> echo" {
    run ./testcli e first-arg second-arg
	assert_success
	assert_line --index 0 --partial 'Executing command "echo" -->   echo second-arg first-arg'
	assert_line --index 1 			'second-arg first-arg'
}

@test "command is expanded correctly: i w f m -> install war from maven, execution of missing program fails" {
	# fixed warning about minimum required version 1.5.0 for 'run' command with parameters
	bats_require_minimum_version 1.5.0
	# -127 disables a bats warning when the command it tests fails with exit code 127
    run -127 ./testcli i w f m

	assert_failure 127
	assert_line --index 0 --partial 'Executing command "install war from maven" -->   ~/bin/install-maven-war.sh'
	assert_line --index 1 --partial	'bin/install-maven-war.sh: No such file or directory'
}



