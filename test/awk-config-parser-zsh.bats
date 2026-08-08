# vim:et:ts=4:sw=4

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
    load 'zsh-helpers'
}

@test "zsh: output=command_names finds expected number of commands" {
    run _zsh_run --cli-run-awk-command output=command_names
	assert_equal "23" "${#lines[@]}"
	assert_line "install war from maven"
}

@test "zsh: output=commands finds expected number of commands" {
    run _zsh_run --cli-run-awk-command output=commands
	assert_success
	assert_equal "23" "${#lines[@]}"
	assert_line "install war from maven        , list,  ~/bin/install-maven-war.sh"
}

@test "zsh: command_filter with regex metacharacter matches literally" {
	run _zsh_run --cli-run-awk-command output=command_names command_filter="ech."
	assert_success
	assert_equal "${#lines[@]}" "0"
}
