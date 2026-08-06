# vim:et:ts=4:sw=4

#
# Tests command word expansion: $variable, &function, and list|expansion
#

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"

    # inject test functions and exported variable into [env] section
    sed '/^\[commands\]/i \
export __TEST_EXPANSION_WORDS="one two three"\
single_word_func() { echo "alpha"; }\
multi_word_func() { echo "alpha beta gamma"; }\
empty_func() { :; }' ~/.testcli.conf > ~/.testcli.conf.tmp && mv ~/.testcli.conf.tmp ~/.testcli.conf

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
}

# --- $variable expansion ---

# execution

@test "bash: \$variable expansion executes" {
	run ./testcli dollar-expansion one
	assert_success
	assert_output "one"
}

@test "bash: \$variable expansion with \\0 placeholder replaces command word" {
	run ./testcli dollar-expansion two
	assert_success
	assert_output "two"
}

# completion

@test "bash: \$variable expansion completes all words" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "dollar-expansion")"
	assert_equal "$result" 'one two three'
}

# --- |list expansion ---

# execution

@test "bash: |list expansion executes" {
	run ./testcli list-expansion-words one
	assert_success
	assert_output "one"
}

@test "bash: |list expansion with \\0 placeholder replaces command word" {
	run ./testcli list-expansion-words two
	assert_success
	assert_output "two"
}

# completion

@test "bash: |list expansion completes all words" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "list-expansion-words")"
	assert_equal "$result" 'one two three'
}

# --- &function expansion ---

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
