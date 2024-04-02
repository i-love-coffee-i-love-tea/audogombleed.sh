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

@test "prints embedded awk script" {
    run ./testcli --cli-print-awk-script
	assert_line '#!/usr/bin/awk -f'
	assert_line 'BEGIN {'
	assert_line 'END {'
}
