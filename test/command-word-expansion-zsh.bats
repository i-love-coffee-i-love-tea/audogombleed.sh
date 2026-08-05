# vim:et:ts=4:sw=4

#
# Tests command word expansion under zsh: $variable, &function, and list|expansion
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
    load 'zsh-helpers'
}

# execution

@test "zsh: &function expansion executes with single-word function" {
	run _zsh_run single-word-func alpha
	assert_success
	assert_output "alpha"
}

@test "zsh: &function expansion executes with multi-word function" {
	run _zsh_run multi-word-func alpha
	assert_success
	assert_output "alpha"
}

@test "zsh: &function expansion with \\0 placeholder replaces command word" {
	run _zsh_run multi-word-func beta
	assert_success
	assert_output "beta"
}

# completion

@test "zsh: &function expansion completes single-word function" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "single-word-func"
	assert_line "alpha"
}

@test "zsh: &function expansion completes multi-word function" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "multi-word-func"
	assert_line "alpha"
	assert_line "beta"
	assert_line "gamma"
}

# edge cases

@test "zsh: &function expansion with empty function returns no completions" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "empty-func"
	assert_output ""
}

@test "zsh: &function expansion with empty function returns exit code 51" {
	run _zsh_run empty-func something
	assert_failure 51
}
