# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests completion edge cases under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# ── Multi-word command completion ──

@test "fish: multi-word command completion at position 3" {
    run _fish_eval '_cli_complete_command 3 k get'
    assert_success
    assert_line "pods"
    assert_line "services"
    assert_line "nodes"
}

@test "fish: multi-word command completion at position 4" {
    run _fish_eval '_cli_complete_command 4 k logs default'
    assert_success
}

# ── First word with no prefix returns all commands ──

@test "fish: empty prefix returns all commands" {
    run _fish_eval 'count (_cli_getfirstwords "")'
    assert_success
    [ "$output" -gt 0 ]
}

# ── Deduplication in first-word completion ──

@test "fish: first word 'k' returns only one 'k' entry" {
    run _fish_eval '_cli_getfirstwords k'
    assert_success
    [ "${#lines[@]}" -eq 1 ]
}

# ── Command descriptions in completion ──

@test "fish: first word completion includes descriptions" {
    run _fish_eval '_cli_getfirstwords e'
    assert_success
    [[ "$output" == *$'\t'* ]]
}

# ── Variable expansion completion ──

@test "fish: variable expansion command completes all words" {
    run _fish_eval '_cli_complete_command 2 var-expansion'
    assert_success
    assert_line --partial "first"
    assert_line --partial "second"
}

# ── List argument from-variable with prefix filter ──

@test "fish: list from-variable filters by prefix" {
    run _fish_eval '_cli_complete_arg 0 "opt" list-argument from-variable'
    assert_success
    assert_line "option1"
    assert_line "option2"
    assert_line "option3"
}

# ── List argument from-function with prefix filter ──

@test "fish: list from-function filters by prefix" {
    run _fish_eval '_cli_complete_arg 0 "opt" list-argument from-function'
    assert_success
    assert_line "opt1"
    assert_line "opt2"
}
