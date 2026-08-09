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
}

@test "output=command_names finds expected number of commands" {
    run ./testcli --cli-run-awk-command output=command_names
	assert_equal "23" "${#lines[@]}"
	assert_line "install war from maven"
}

@test "output=commands finds expected number of commands" {
    run ./testcli --cli-run-awk-command output=commands
	assert_success
	assert_equal "23" "${#lines[@]}"
	assert_line "install war from maven        , list,  ~/bin/install-maven-war.sh"
}

@test "returns vars describing command args for complete command: echo" {
	run ./testcli --cli-run-awk-command output=commands command_filter="echo"
	assert_line 'declare -g -A __CMD_ARG __CMD_ARG_TYPE __CMD_ARG_VALUE __CMD_ARG_DESC __CMD_ARG_NAME'
	assert_line '__CMD="echo"'
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

@test "custom argument descriptions are parsed for list type" {
	# Append a command with descriptions to the config
	cat >> ~/.testcli.conf <<'EOF'

test-desc-list: echo
	:env:list:staging|prod:target environment
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="test-desc-list"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="env"'
	assert_line '__CMD_ARG_TYPE[0]="list"'
	assert_line '__CMD_ARG_VALUE[0]="staging|prod"'
	assert_line '__CMD_ARG_DESC[0]="target environment"'
}

@test "custom argument descriptions are parsed for non-value types" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-file: echo
	:path:FILE::path to input
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="test-desc-file"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="FILE"'
	assert_line '__CMD_ARG_VALUE[0]=""'
	assert_line '__CMD_ARG_DESC[0]="path to input"'
}

@test "FILE type with glob filter is parsed as value" {
	cat >> ~/.testcli.conf <<'EOF'

test-file-glob: echo
	:path:FILE:*.txt
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="test-file-glob"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="FILE"'
	assert_line '__CMD_ARG_VALUE[0]="*.txt"'
	assert_line '__CMD_ARG_DESC[0]=""'
}

@test "FILE type with glob filter and description" {
	cat >> ~/.testcli.conf <<'EOF'

test-file-glob-desc: echo
	:path:FILE:*.txt:text files
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="test-file-glob-desc"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="FILE"'
	assert_line '__CMD_ARG_VALUE[0]="*.txt"'
	assert_line '__CMD_ARG_DESC[0]="text files"'
}

@test "DIR type with glob filter is parsed as value" {
	cat >> ~/.testcli.conf <<'EOF'

test-dir-glob: echo
	:path:DIR:*test*
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="test-dir-glob"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="DIR"'
	assert_line '__CMD_ARG_VALUE[0]="*test*"'
	assert_line '__CMD_ARG_DESC[0]=""'
}

@test "FILE_OR_DIR type with glob filter and description" {
	cat >> ~/.testcli.conf <<'EOF'

test-file-or-dir-glob: echo
	:path:FILE_OR_DIR:*.log:log files
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="test-file-or-dir-glob"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="FILE_OR_DIR"'
	assert_line '__CMD_ARG_VALUE[0]="*.log"'
	assert_line '__CMD_ARG_DESC[0]="log files"'
}

@test "custom argument descriptions are parsed for int_range type" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-range: echo
	:port:int_range:1-65535:TCP port number
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="test-desc-range"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="port"'
	assert_line '__CMD_ARG_TYPE[0]="int_range"'
	assert_line '__CMD_ARG_VALUE[0]="1-65535"'
	assert_line '__CMD_ARG_DESC[0]="TCP port number"'
}

@test "custom argument descriptions are parsed for eval type" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-eval: echo
	:deployment:eval:get_deployments:target deployment
EOF
	run ./testcli --cli-run-awk-command output=commands command_filter="test-desc-eval"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="deployment"'
	assert_line '__CMD_ARG_TYPE[0]="eval"'
	assert_line '__CMD_ARG_VALUE[0]="get_deployments"'
	assert_line '__CMD_ARG_DESC[0]="target deployment"'
}

@test "command_filter with regex metacharacter matches literally" {
	# The dot in "ech." should match only a literal dot, not any character
	# "echo" has no literal dot, so "ech." should not match
	run ./testcli --cli-run-awk-command output=command_names command_filter="ech."
	assert_success
	# Should return no results since no command contains a literal dot after "ech"
	assert_equal "${#lines[@]}" "0"
}
