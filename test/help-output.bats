setup_file() {
  	echo "# setup_file" >&3
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
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

@test "prints formatted help for install command as expected" {
    run ./testcli install -?

	assert_success
	assert_line "  | example of deeper structure"
	assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
	assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
	assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
	assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}
