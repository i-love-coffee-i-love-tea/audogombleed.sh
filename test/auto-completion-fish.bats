# vim:et:ts=4:sw=4

#
# Fish tab completion tests.
# Fish completions are plain words (no [description] suffixes).
# Output is one completion per line.

setup_file() {
  	echo "# setup_file" >&3
    load 'common-setup'
    load 'common-setup-fish'
    _common_setup_fish __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
  	echo "# teardown_file" >&3
    load 'common-teardown'
    _common_teardown
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'fish-helpers'
}

# ── Smoke: wrapper sources under fish ──

@test "fish: wrapper sources without error" {
    run fish -c 'source ./testcli; echo "ok"'
    assert_success
    assert_output "ok"
}

@test "fish: _cli_execute function exists after sourcing" {
    run fish -c 'source ./testcli; functions -q _cli_execute; and echo "exists"'
    assert_success
    assert_output "exists"
}

@test "fish: _awk function exists after sourcing" {
    run fish -c 'source ./testcli; functions -q _awk; and echo "exists"'
    assert_success
    assert_output "exists"
}

# ── AWK parser integration ──

@test "fish: _awk output=command_names returns commands" {
    run fish -c 'source ./testcli; count (_awk output=command_names)'
    assert_success
    # example.conf has many commands
    [ "$output" -gt 0 ]
}

@test "fish: _awk output=commands returns command list" {
    run fish -c 'source ./testcli; count (_awk output=commands)'
    assert_success
    [ "$output" -gt 0 ]
}

@test "fish: _awk output=help returns help text" {
    run fish -c 'source ./testcli; count (_awk output=help do_format=1)'
    assert_success
    [ "$output" -gt 0 ]
}

@test "fish: _awk output=env returns env lines" {
    run fish -c 'source ./testcli; count (_awk output=env)'
    assert_success
    [ "$output" -gt 0 ]
}

# ── Command completion: first word ──

@test "fish: first word 'e' -> echo" {
    run fish -c 'source ./testcli; _cli_getfirstwords e'
    assert_success
    assert_output "echo"
}

@test "fish: first word 'var' -> var-expansion" {
    run fish -c 'source ./testcli; _cli_getfirstwords var'
    assert_success
    assert_output "var-expansion"
}

@test "fish: first word 'func' -> function-expansion" {
    run fish -c 'source ./testcli; _cli_getfirstwords func'
    assert_success
    assert_output "function-expansion"
}

@test "fish: first word 'list' -> list-expansion list-argument" {
    run fish -c 'source ./testcli; _cli_getfirstwords list'
    assert_success
    assert_line "list-expansion"
    assert_line "list-argument"
}

@test "fish: first word 'k' -> k" {
    run fish -c 'source ./testcli; _cli_getfirstwords k'
    assert_success
    assert_output "k"
}

@test "fish: first word 'false' -> false" {
    run fish -c 'source ./testcli; _cli_getfirstwords false'
    assert_success
    assert_output "false"
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
    # May return 0 or more files depending on cwd; just verify no error
}

# ── Command execution ──

@test "fish: execute 'return2' returns exit code2" {
    run _fish_run return2
    assert_failure
    [ "$status" -eq 2 ]
}

@test "fish: execute 'false' returns non-zero" {
    run _fish_run false
    assert_failure
}

@test "fish: execute with no command prints usage" {
    run fish -c 'source ./testcli; _cli_execute 2>&1'
    assert_output --partial "no command"
}

# ── Help output ──

@test "fish: '?' shows all commands" {
    run _fish_run '?'
    assert_success
    [ "${#lines[@]}" -gt 0 ]
}

@test "fish: 'echo ?' shows echo help" {
    run _fish_run echo '?'
    assert_success
    assert_output --partial "echo"
}

# ── Abbreviation expansion ──

@test "fish: abbreviation 'e' -> 'echo'" {
    run fish -c 'source ./testcli; _cli_expand_abbreviated_command e'
    assert_success
    assert_output "echo"
}

@test "fish: abbreviation 'k g' -> 'k get'" {
    run fish -c 'source ./testcli; _cli_expand_abbreviated_command k g'
    assert_success
    assert_output "k get"
}

@test "fish: abbreviation 'k r d' -> 'k restart default'" {
    run fish -c 'source ./testcli; _cli_expand_abbreviated_command k r d'
    assert_success
    assert_output "k restart default"
}

# ── Environment ──

@test "fish: __CLI_PROGNAME is set after sourcing" {
    run fish -c 'source ./testcli; echo $__CLI_PROGNAME'
    assert_success
    assert_output "testcli"
}

@test "fish: __CLI_CONFIG_FILE is set after sourcing" {
    run fish -c 'source ./testcli; echo $__CLI_CONFIG_FILE'
    assert_success
    assert_output "$HOME/.testcli.conf"
}
