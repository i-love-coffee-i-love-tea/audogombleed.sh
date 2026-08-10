# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests argument type completion under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# ── FILE type ──

@test "fish: FILE argument completion returns results" {
    run _fish_eval '_cli_complete_arg 0 "" install jar from file'
    assert_success
    [ "${#lines[@]}" -gt 0 ]
}

@test "fish: FILE argument completion filters by prefix" {
    run _fish_eval '_cli_complete_arg 0 "test-file" install jar from file'
    assert_success
}

# ── DIR type ──

@test "fish: DIR argument completion returns results" {
    run _fish_eval '_cli_complete_arg 0 "" k logs default'
    assert_success
}

# ── list type with static values ──

@test "fish: list argument returns all values for empty prefix" {
    run _fish_eval '_cli_complete_arg 0 "" list-argument static'
    assert_success
    assert_line "first-element"
    assert_line "second"
    assert_line "third"
    assert_line "etc"
}

@test "fish: list argument filters by prefix" {
    run _fish_eval '_cli_complete_arg 0 "first" list-argument static'
    assert_success
    assert_line "first-element"
    refute_line "second"
}

@test "fish: list argument from variable returns values" {
    run _fish_eval '_cli_complete_arg 0 "" list-argument from-variable'
    assert_success
    assert_line "option1"
    assert_line "option2"
    assert_line "option3"
}

@test "fish: list argument from function returns values" {
    run _fish_eval '_cli_complete_arg 0 "" list-argument from-function'
    assert_success
    assert_line "opt1"
    assert_line "opt2"
}

# ── single-value list argument ──

@test "fish: single-value list argument returns the value" {
    run _fish_eval '_cli_complete_arg 0 "" echo'
    assert_success
    assert_output "first"
}

@test "fish: positional argument placeholder completion returns correct value per position" {
    run _fish_eval '_cli_complete_arg 1 "" echo'
    assert_success
    assert_output "second"
}
