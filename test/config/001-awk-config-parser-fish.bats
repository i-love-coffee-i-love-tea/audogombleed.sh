# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests AWK config parser under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: output=command_names finds expected number of commands" {
    run _fish_run --cli-run-awk-command output=command_names
	assert_success
	assert_equal "23" "${#lines[@]}"
	assert_line "install war from maven"
}

@test "fish: output=commands finds expected number of commands" {
    run _fish_run --cli-run-awk-command output=commands
	assert_success
	assert_equal "23" "${#lines[@]}"
	assert_line "install war from maven        , list,  ~/bin/install-maven-war.sh"
}

@test "fish: returns vars describing command args for complete command: echo" {
	run _fish_run --cli-run-awk-command output=commands command_filter="echo"
	assert_success
}

@test "fish: custom argument descriptions are parsed for list type" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-list: echo
	:env:list:staging|prod:target environment
EOF
	run _fish_run --cli-run-awk-command output=commands command_filter="test-desc-list"
	assert_success
}

@test "fish: custom argument descriptions are parsed for non-value types" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-file: echo
	:path:FILE::path to input
EOF
	run _fish_run --cli-run-awk-command output=commands command_filter="test-desc-file"
	assert_success
}

@test "fish: FILE type with glob filter is parsed as value" {
	cat >> ~/.testcli.conf <<'EOF'

test-file-glob: echo
	:path:FILE:*.txt
EOF
	run _fish_run --cli-run-awk-command output=commands command_filter="test-file-glob"
	assert_success
}

@test "fish: FILE type with glob filter and description" {
	cat >> ~/.testcli.conf <<'EOF'

test-file-glob-desc: echo
	:path:FILE:*.txt:text files
EOF
	run _fish_run --cli-run-awk-command output=commands command_filter="test-file-glob-desc"
	assert_success
}

@test "fish: DIR type with glob filter is parsed as value" {
	cat >> ~/.testcli.conf <<'EOF'

test-dir-glob: echo
	:path:DIR:*test*
EOF
	run _fish_run --cli-run-awk-command output=commands command_filter="test-dir-glob"
	assert_success
}

@test "fish: FILE_OR_DIR type with glob filter and description" {
	cat >> ~/.testcli.conf <<'EOF'

test-file-or-dir-glob: echo
	:path:FILE_OR_DIR:*.log:log files
EOF
	run _fish_run --cli-run-awk-command output=commands command_filter="test-file-or-dir-glob"
	assert_success
}

@test "fish: custom argument descriptions are parsed for int_range type" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-range: echo
	:port:int_range:1-65535:TCP port number
EOF
	run _fish_run --cli-run-awk-command output=commands command_filter="test-desc-range"
	assert_success
}

@test "fish: custom argument descriptions are parsed for eval type" {
	cat >> ~/.testcli.conf <<'EOF'

test-desc-eval: echo
	:deployment:eval:get_deployments:target deployment
EOF
	run _fish_run --cli-run-awk-command output=commands command_filter="test-desc-eval"
	assert_success
}

@test "fish: command_filter with regex metacharacter matches literally" {
	run _fish_run --cli-run-awk-command output=command_names command_filter="ech."
	assert_success
	assert_equal "${#lines[@]}" "0"
}
