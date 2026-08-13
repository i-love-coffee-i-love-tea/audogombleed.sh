# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-062
@test "zsh: output=command_names finds expected number of commands" {
    run _zsh_run --cli-run-awk-command output=command_names
	assert_equal "${#lines[@]}" "32"
	assert_line "install war from maven"
}

# bats test_tags=id:zsh-063
@test "zsh: output=commands finds expected number of commands" {
    run _zsh_run --cli-run-awk-command output=commands
	assert_success
	assert_equal "${#lines[@]}" "32"
	assert_line "install war from maven        , list,  ~/bin/install-maven-war.sh"
}

# bats test_tags=id:zsh-064
@test "zsh: command_filter with regex metacharacter matches literally" {
	run _zsh_run --cli-run-awk-command output=command_names command_filter="ech."
	assert_success
	assert_equal "${#lines[@]}" "0"
}

# bats test_tags=id:zsh-065
@test "zsh: returns vars describing command args for complete command: echo" {
	run _zsh_run --cli-run-awk-command output=commands command_filter="echo"
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
@test "zsh: returns vars describing command args for complete command: install war from file" {
	skip "can't be called from outside"
}

# bats test_tags=id:zsh-066
@test "zsh: custom argument descriptions are parsed for list type" {
	# Append a command with descriptions to the config
	cat >> ~/.testcli.conf <<'EOF'

test-desc-list: echo
	:env:list:staging|prod:target environment
EOF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-desc-list"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="env"'
	assert_line '__CMD_ARG_TYPE[0]="list"'
	assert_line '__CMD_ARG_VALUE[0]="staging|prod"'
	assert_line '__CMD_ARG_DESC[0]="target environment"'
}

# bats test_tags=id:zsh-067
@test "zsh: custom argument descriptions are parsed for non-value types" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-file: echo
	:path:FILE::path to input
EOF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-desc-file"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="FILE"'
	assert_line '__CMD_ARG_VALUE[0]=""'
	assert_line '__CMD_ARG_DESC[0]="path to input"'
}

# bats test_tags=id:zsh-068
@test "zsh: FILE type with glob filter is parsed as value" {
	cat >> ~/.testcli.conf <<'EOF'

test-file-glob: echo
	:path:FILE:*.txt
EOF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-file-glob"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="FILE"'
	assert_line '__CMD_ARG_VALUE[0]="*.txt"'
	assert_line '__CMD_ARG_DESC[0]=""'
}

# bats test_tags=id:zsh-069
@test "zsh: FILE type with glob filter and description" {
	cat >> ~/.testcli.conf <<'EOF'

test-file-glob-desc: echo
	:path:FILE:*.txt:text files
EOF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-file-glob-desc"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="FILE"'
	assert_line '__CMD_ARG_VALUE[0]="*.txt"'
	assert_line '__CMD_ARG_DESC[0]="text files"'
}

# bats test_tags=id:zsh-070
@test "zsh: DIR type with glob filter is parsed as value" {
	cat >> ~/.testcli.conf <<'EOF'

test-dir-glob: echo
	:path:DIR:*test*
EOF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-dir-glob"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="DIR"'
	assert_line '__CMD_ARG_VALUE[0]="*test*"'
	assert_line '__CMD_ARG_DESC[0]=""'
}

# bats test_tags=id:zsh-071
@test "zsh: FILE_OR_DIR type with glob filter and description" {
	cat >> ~/.testcli.conf <<'EOF'

test-file-or-dir-glob: echo
	:path:FILE_OR_DIR:*.log:log files
EOF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-file-or-dir-glob"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="path"'
	assert_line '__CMD_ARG_TYPE[0]="FILE_OR_DIR"'
	assert_line '__CMD_ARG_VALUE[0]="*.log"'
	assert_line '__CMD_ARG_DESC[0]="log files"'
}

# bats test_tags=id:zsh-072
@test "zsh: custom argument descriptions are parsed for int_range type" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-range: echo
	:port:int_range:1-65535:TCP port number
EOF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-desc-range"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="port"'
	assert_line '__CMD_ARG_TYPE[0]="int_range"'
	assert_line '__CMD_ARG_VALUE[0]="1-65535"'
	assert_line '__CMD_ARG_DESC[0]="TCP port number"'
}

# bats test_tags=id:zsh-073
@test "zsh: custom argument descriptions are parsed for eval type" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-eval: echo
	:deployment:eval:get_deployments:target deployment
EOF
	run _zsh_run --cli-run-awk-command output=commands command_filter="test-desc-eval"
	assert_success
	assert_line '__CMD_ARG_NAME[0]="deployment"'
	assert_line '__CMD_ARG_TYPE[0]="eval"'
	assert_line '__CMD_ARG_VALUE[0]="get_deployments"'
	assert_line '__CMD_ARG_DESC[0]="target deployment"'
}
