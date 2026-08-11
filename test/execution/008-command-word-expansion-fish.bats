# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
# Tests command word expansion: $variable, &function, and list|expansion under fish
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    # Inject fish-native test functions and variable into [env.fish] section
    sed -i '/^\[commands\]/i\
[env.fish]\
function single_word_func\
    echo "alpha"\
end\
function multi_word_func\
    echo "alpha beta gamma"\
end\
function empty_func\
    # intentionally empty\
end\
' ~/.testcli.conf
    # Set the exported variable
    sed -i '/^\[env\]/a export __TEST_EXPANSION_WORDS="one two three"' ~/.testcli.conf
    # Append test commands
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
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# --- $variable expansion ---

@test "fish: \$variable expansion executes" {
	run _fish_run dollar-expansion one
	assert_success
	assert_output "one"
}

@test "fish: \$variable expansion with \\0 placeholder replaces command word" {
	run _fish_run dollar-expansion two
	assert_success
	assert_output "two"
}

@test "fish: \$variable expansion completes all words" {
    run _fish_eval '_cli_complete_command 2 dollar-expansion'
    assert_success
    assert_line "one"
    assert_line "two"
    assert_line "three"
}

# --- |list expansion ---

@test "fish: |list expansion executes" {
	run _fish_run list-expansion-words one
	assert_success
	assert_output "one"
}

@test "fish: |list expansion with \\0 placeholder replaces command word" {
	run _fish_run list-expansion-words two
	assert_success
	assert_output "two"
}

@test "fish: |list expansion completes all words" {
    run _fish_eval '_cli_complete_command 2 list-expansion-words'
    assert_success
    assert_line "one"
    assert_line "two"
    assert_line "three"
}

# --- &function expansion ---

@test "fish: &function expansion executes with single-word function" {
	run _fish_run single-word-func alpha
	assert_success
	assert_output "alpha"
}

@test "fish: &function expansion executes with multi-word function" {
	run _fish_run multi-word-func alpha
	assert_success
	assert_output "alpha"
}

@test "fish: &function expansion with \\0 placeholder replaces command word" {
	run _fish_run multi-word-func beta
	assert_success
	assert_output "beta"
}

@test "fish: &function expansion completes single-word function" {
    run _fish_eval '_cli_complete_command 2 single-word-func'
    assert_success
    assert_line "alpha"
}

@test "fish: &function expansion completes multi-word function" {
    run _fish_eval '_cli_complete_command 2 multi-word-func'
    assert_success
    assert_line "alpha"
    assert_line "beta"
    assert_line "gamma"
}

@test "fish: &function expansion with empty function returns no completions" {
    run _fish_eval '_cli_complete_command 2 empty-func'
    assert_success
    assert_output ""
}

@test "fish: &function expansion with empty function returns exit code 51" {
	run _fish_run empty-func something
	assert_failure 51
}
