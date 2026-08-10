# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish
#
# Tests tab completion under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# ── Command completion: first word ──

@test "fish: first word 'e' -> echo" {
    run fish -c 'source ./testcli; _cli_getfirstwords e'
    assert_success
    assert_line --partial "echo"
}

@test "fish: first word 'var' -> var-expansion" {
    run fish -c 'source ./testcli; _cli_getfirstwords var'
    assert_success
    assert_line --partial "var-expansion"
}

@test "fish: first word 'func' -> function-expansion" {
    run fish -c 'source ./testcli; _cli_getfirstwords func'
    assert_success
    assert_line --partial "function-expansion"
}

@test "fish: first word 'list' -> list-expansion list-argument" {
    run fish -c 'source ./testcli; _cli_getfirstwords list'
    assert_success
    assert_line --partial "list-expansion"
    assert_line --partial "list-argument"
}

@test "fish: first word 'k' -> k" {
    run fish -c 'source ./testcli; _cli_getfirstwords k'
    assert_success
    [[ "$output" =~ ^k ]]
}

@test "fish: first word 'false' -> false" {
    run fish -c 'source ./testcli; _cli_getfirstwords false'
    assert_success
    assert_line --partial "false"
}

@test "fish: first word '' -> all commands" {
    run fish -c 'source ./testcli; count (_cli_getfirstwords "")'
    assert_success
    [ "$output" -gt 0 ]
}

# ── Command completion: second word ──

@test "fish: 'k get' -> pods services nodes" {
    run fish -c 'source ./testcli; _cli_complete_command 3 k get'
    assert_success
    assert_line "pods"
    assert_line "services"
    assert_line "nodes"
}

@test "fish: 'k logs' -> default kube-system" {
    run fish -c 'source ./testcli; _cli_complete_command 3 k logs'
    assert_success
    assert_line "default"
    assert_line "kube-system"
}

@test "fish: 'k restart' -> default kube-system" {
    run fish -c 'source ./testcli; _cli_complete_command 3 k restart'
    assert_success
    assert_line "default"
    assert_line "kube-system"
}

@test "fish: 'list-argument' -> static from-function from-variable" {
    run fish -c 'source ./testcli; _cli_complete_command 2 list-argument'
    assert_success
    assert_line "static"
    assert_line "from-function"
    assert_line "from-variable"
}

# ── Argument completion: list type ──

@test "fish: echo arg list: first -> second" {
    run fish -c 'source ./testcli; _cli_complete_arg 1 second echo'
    assert_success
    assert_output "second"
}

@test "fish: list-argument static -> first-element second third etc" {
    run fish -c 'source ./testcli; _cli_complete_arg 0 "" list-argument static'
    assert_success
    assert_line "first-element"
    assert_line "second"
    assert_line "third"
    assert_line "etc"
}

@test "fish: list-argument from-variable -> option1 option2 option3" {
    run fish -c 'source ./testcli; _cli_complete_arg 0 "" list-argument from-variable'
    assert_success
    assert_line "option1"
    assert_line "option2"
    assert_line "option3"
}

# ── Argument completion: eval type ──

@test "fish: list-argument from-function -> opt1 opt2" {
    run fish -c 'source ./testcli; _cli_complete_arg 0 "" list-argument from-function'
    assert_success
    assert_line "opt1"
    assert_line "opt2"
}

# ── Argument completion: file/dir types ──

@test "fish: FILE arg type returns file completions" {
    run fish -c 'source ./testcli; _cli_complete_arg 0 "" install jar from file'
    assert_success
}
