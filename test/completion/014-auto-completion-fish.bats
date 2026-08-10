# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests auto-completion for various command types under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# ── first-word completion ──

@test "fish: first word completion matches command by prefix" {
    run _fish_eval '_cli_getfirstwords e'
    assert_success
    assert_line --partial "echo"
}

@test "fish: single-value list argument returns value" {
    run _fish_eval '_cli_complete_arg 0 "" echo'
    assert_success
    assert_line "first"
}

@test "fish: positional argument at index 0 returns first arg" {
    run _fish_eval '_cli_complete_arg 0 "" echo'
    assert_success
    assert_output "first"
}

@test "fish: positional argument at index 1 returns second arg" {
    run _fish_eval '_cli_complete_arg 1 "" echo'
    assert_success
    assert_output "second"
}

# ── variable expansion completions ──

@test "fish: variable expansion first word completion" {
    run _fish_eval '_cli_getfirstwords var'
    assert_success
    assert_line --partial "var-expansion"
}

@test "fish: variable expansion second word completion" {
    run _fish_eval '_cli_complete_command 2 var-expansion'
    assert_success
    assert_line --partial "first"
    assert_line --partial "second"
}

# ── function expansion completions ──

@test "fish: function expansion first word completion" {
    run _fish_eval '_cli_getfirstwords func'
    assert_success
    assert_line --partial "function-expansion"
}

@test "fish: function expansion second word completion" {
    run _fish_eval '_cli_complete_command 2 function-expansion'
    assert_success
    assert_line --partial "thievery"
    assert_line --partial "corporation"
}

# ── list expansion completions ──

@test "fish: list expansion first word completion" {
    run _fish_eval '_cli_getfirstwords list'
    assert_success
    assert_line --partial "list-expansion"
    assert_line --partial "list-argument"
}

@test "fish: list expansion second word completion" {
    run _fish_eval '_cli_complete_command 2 list-expansion'
    assert_success
    assert_line --partial "thievery"
    assert_line --partial "corporation"
}

# ── hierarchical command completions ──

@test "fish: hierarchical command second word completion" {
    run _fish_eval '_cli_complete_command 2 install'
    assert_success
    assert_line "jar"
    assert_line "war"
}

@test "fish: hierarchical command fourth word completion" {
    run _fish_eval '_cli_complete_command 4 install jar from'
    assert_success
    assert_line "file"
    assert_line "maven"
}

# ── list-argument completions ──

@test "fish: list-argument second word completion" {
    run _fish_eval '_cli_complete_command 2 list-argument'
    assert_success
    assert_line --partial "static"
    assert_line --partial "from-function"
    assert_line --partial "from-variable"
}
