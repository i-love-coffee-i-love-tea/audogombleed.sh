# vim:et:ts=4:sw=4

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
    load 'zsh-helpers'
}

@test "zsh: prints embedded awk script" {
    run _zsh_run --cli-print-awk-script
	assert_line '#!/usr/bin/awk -f'
	assert_line 'BEGIN {'
	assert_line 'END {'
}

@test "zsh: --version prints version string" {
    run _zsh_run --version
    assert_success
    assert_output "1.2.0"
}
