setup_file() {
  	echo "# setup_file" >&3
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="n"
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

@test "output=command_names finds expected number of commands" {
    run ./testcli --cli-run-awk-command output=command_names
	assert_equal "16" "${#lines[@]}"
	assert_line "install war from maven"
}

@test "output=commands finds expected number of commands" {
    run ./testcli --cli-run-awk-command output=commands
	assert_success
	assert_equal "16" "${#lines[@]}"
	assert_line "install war from maven        , list,  ~/bin/install-maven-war.sh"
}
