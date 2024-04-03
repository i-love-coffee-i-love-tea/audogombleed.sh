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

@test "returns vars describing command args for complete command: echo" {
	run ./testcli --cli-run-awk-command output=commands command_filter="echo"
	assert_line 'declare -g -A __CMD_ARG __CMD_ARG_TYPE __CMD_ARG_VALUE __CMD_ARG_DESC __CMD_ARG_NAME'
	assert_line '__CMD="echo"'
	assert_line '__CMD_EXEC=" \0 \2 \1"'
    assert_line '__CMD_ARG[0]="list"'
    assert_line '__CMD_ARG_NAME[0]="arg1"'
    assert_line '__CMD_ARG_TYPE[0]="list"'
    assert_line '__CMD_ARG_DESC[0]=""'
    assert_line '__CMD_ARG_VALUE[0]="first"'
    assert_line '__CMD_ARG[1]="list"'
    assert_line '__CMD_ARG_NAME[1]="arg2"'
    assert_line '__CMD_ARG_TYPE[1]="list"'
    assert_line '__CMD_ARG_DESC[1]=""'
    assert_line '__CMD_ARG_VALUE[1]="second"'
	assert_success
}

# works in the script, but can't be called from outside
#@test "returns vars describing command args for complete command: install war from file" {
#	run ./testcli --cli-run-awk-command output=commands command_filter="install war from file"
#	declare -g -A __CMD_ARG __CMD_ARG_TYPE __CMD_ARG_VALUE __CMD_ARG_DESC __CMD_ARG_NAME
#	assert_line '__CMD="install war from file"'
#	assert_line '__CMD_EXEC=" echo"'
#	assert_line '__CMD_ARG[0]="list"'
#	assert_line '__CMD_ARG_NAME[0]="mvn-coords"'
#	assert_line '__CMD_ARG_TYPE[0]="FILE"'
#	assert_line '__CMD_ARG_DESC[0]=""'
#	assert_line '__CMD_ARG_VALUE[0]=""'
#	assert_success
#}
