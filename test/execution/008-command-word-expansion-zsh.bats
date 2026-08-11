# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
# Tests command word expansion under zsh: $variable, &function, and list|expansion
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init __CLI_CFG_EXEC_SILENT="y"
}
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# --- $variable expansion ---

# execution

# bats test_tags=id:zsh-137
@test "zsh: \$variable expansion executes" {
	run _zsh_run dollar-expansion one
	assert_success
	assert_output "one"
}

# bats test_tags=id:zsh-138
@test "zsh: \$variable expansion with \\0 placeholder replaces command word" {
	run _zsh_run dollar-expansion two
	assert_success
	assert_output "two"
}

# completion

# bats test_tags=id:zsh-139
@test "zsh: \$variable expansion completes all words" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "dollar-expansion"
	assert_line "one"
	assert_line "two"
	assert_line "three"
}

# --- |list expansion ---

# execution

# bats test_tags=id:zsh-140
@test "zsh: |list expansion executes" {
	run _zsh_run list-expansion-words one
	assert_success
	assert_output "one"
}

# bats test_tags=id:zsh-141
@test "zsh: |list expansion with \\0 placeholder replaces command word" {
	run _zsh_run list-expansion-words two
	assert_success
	assert_output "two"
}

# completion

# bats test_tags=id:zsh-142
@test "zsh: |list expansion completes all words" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "list-expansion-words"
	assert_line "one"
	assert_line "two"
	assert_line "three"
}

# --- &function expansion ---

# execution

# bats test_tags=id:zsh-143
@test "zsh: &function expansion executes with single-word function" {
	run _zsh_run single-word-func alpha
	assert_success
	assert_output "alpha"
}

# bats test_tags=id:zsh-144
@test "zsh: &function expansion executes with multi-word function" {
	run _zsh_run multi-word-func alpha
	assert_success
	assert_output "alpha"
}

# bats test_tags=id:zsh-145
@test "zsh: &function expansion with \\0 placeholder replaces command word" {
	run _zsh_run multi-word-func beta
	assert_success
	assert_output "beta"
}

# completion

# bats test_tags=id:zsh-146
@test "zsh: &function expansion completes single-word function" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "single-word-func"
	assert_line "alpha"
}

# bats test_tags=id:zsh-147
@test "zsh: &function expansion completes multi-word function" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "multi-word-func"
	assert_line "alpha"
	assert_line "beta"
	assert_line "gamma"
}

# edge cases

# bats test_tags=id:zsh-148
@test "zsh: &function expansion with empty function returns no completions" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "empty-func"
	assert_output ""
}

# bats test_tags=id:zsh-149
@test "zsh: &function expansion with empty function returns exit code 51" {
	run _zsh_run empty-func something
	assert_failure 51
}
