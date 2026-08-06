# vim:et:ts=4:sw=4

#
# Tests command word expansion under zsh: $variable, &function, and list|expansion
#

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"

    # inject test functions and exported variable into [env] section
    sed -i '/^\[commands\]/i \
export __TEST_EXPANSION_WORDS="one two three"\
single_word_func() { echo "alpha"; }\
multi_word_func() { echo "alpha beta gamma"; }\
empty_func() { :; }' ~/.testcli.conf

    # append test commands to [commands] section
    cat >> ~/.testcli.conf <<'CMDS'

dollar-expansion
    $__TEST_EXPANSION_WORDS: echo \0
list-expansion-words
    one|two|three: echo \0
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

# --- $variable expansion ---

# execution

@test "zsh: \$variable expansion executes" {
	run _zsh_run dollar-expansion one
	assert_success
	assert_output "one"
}

@test "zsh: \$variable expansion with \\0 placeholder replaces command word" {
	run _zsh_run dollar-expansion two
	assert_success
	assert_output "two"
}

# completion

@test "zsh: \$variable expansion completes all words" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "dollar-expansion"
	assert_line "one"
	assert_line "two"
	assert_line "three"
}

# --- |list expansion ---

# execution

@test "zsh: |list expansion executes" {
	run _zsh_run list-expansion-words one
	assert_success
	assert_output "one"
}

@test "zsh: |list expansion with \\0 placeholder replaces command word" {
	run _zsh_run list-expansion-words two
	assert_success
	assert_output "two"
}

# completion

@test "zsh: |list expansion completes all words" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "list-expansion-words"
	assert_line "one"
	assert_line "two"
	assert_line "three"
}

# --- &function expansion ---

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
