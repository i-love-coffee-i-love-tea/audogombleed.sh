# vim:et:ts=4:sw=4

#
# Tests command word expansion: $variable, &function, and list|expansion
#

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"

    # inject test functions into [env] section (before [commands])
    sed -i '/^\[commands\]/i \
single_word_func() { echo "alpha"; }\
multi_word_func() { echo "alpha beta gamma"; }\
empty_func() { :; }' ~/.testcli.conf

    # append test commands to [commands] section
    cat >> ~/.testcli.conf <<'CMDS'

single-word-func
    &single_word_func: echo \0
multi-word-func
    &multi_word_func: echo \0
empty-func
    &empty_func: echo \0
CMDS
}
teardown_file() {
    load 'common-teardown'
    _common_teardown
}
setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
}

# execution

@test "bash: &function expansion executes with single-word function" {
	run ./testcli single-word-func alpha
	assert_success
	assert_output "alpha"
}

@test "bash: &function expansion executes with multi-word function" {
	run ./testcli multi-word-func alpha
	assert_success
	assert_output "alpha"
}

@test "bash: &function expansion with \\0 placeholder replaces command word" {
	run ./testcli multi-word-func beta
	assert_success
	assert_output "beta"
}

# completion

@test "bash: &function expansion completes single-word function" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "single-word-func")"
	assert_equal "$result" 'alpha'
}

@test "bash: &function expansion completes multi-word function" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "multi-word-func")"
	assert_equal "$result" 'alpha beta gamma'
}

# edge cases

@test "bash: &function expansion with empty function returns no completions" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "empty-func")"
	assert_equal "$result" ''
}

@test "bash: &function expansion with empty function returns exit code 51" {
	run ./testcli empty-func something
	assert_failure 51
}
