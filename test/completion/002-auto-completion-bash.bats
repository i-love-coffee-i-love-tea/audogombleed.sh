# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:bash

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# echo
# bats test_tags=id:bash-029
@test "returns correct completion list: echo		-> first" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "echo")"
	assert_equal "$result" 'first' 
}
# bats test_tags=id:bash-030
@test "returns correct completion list: echo first 		-> second" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "echo" "first")"
	assert_equal "$result" 'second' 
}

# var-expansion
# bats test_tags=id:bash-031
@test "returns correct completion list: var-expansion	-> first second" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "var-expansion")"
	assert_equal "$result" 'first second' 
}
# function-expansion
# bats test_tags=id:bash-032
@test "returns correct completion list: function-expansion	-> thievery corporation" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "function-expansion")"
	assert_equal "$result" 'thievery corporation' 
}
# list-expansion
# bats test_tags=id:bash-033
@test "returns correct completion list: list-expansion	-> thievery corporation" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "list-expansion")"
	assert_equal "$result" 'thievery corporation' 
}

# list args
# bats test_tags=id:bash-034
@test "returns correct completion list: list-argument	-> static from-function from-variable" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "list-argument")"
	assert_equal "$result" 'static from-function from-variable' 
}
# bats test_tags=id:bash-035
@test "returns correct completion list: list-argument static -> first-element second third etc" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "list-argument" "static")"
	assert_equal "$result" 'first-element second third etc' 
}
# bats test_tags=id:bash-036
@test "returns correct completion list: list-argument from-function -> opt1 opt2" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "list-argument" "from-function")"
	assert_equal "$result" 'opt1 opt2' 
}
# bats test_tags=id:bash-037
@test "returns correct completion list: list-argument from-variable -> option1 option2 option3" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "list-argument" "from-variable")"
	assert_equal "$result" 'option1 option2 option3' 
}

# commands without args (tests the space fix in _cli_complete_arg)
# bats test_tags=id:bash-038
@test "returns empty completion for command without args: false" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "false")"
	assert_equal "$result" ''
}
# bats test_tags=id:bash-039
@test "returns empty completion for command without args: return2" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "return2")"
	assert_equal "$result" ''
}

# install
# bats test_tags=id:bash-040
@test "returns correct completion list: install 		-> jar war" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "install")"
	assert_equal "$result" 'jar war' 
}
# bats test_tags=id:bash-041
@test "returns correct completion list: install jar		-> from" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "install" "jar")"
	assert_equal "$result" 'from' 
}
# bats test_tags=id:bash-042
@test "returns correct completion list: install war		-> from" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "install" "war")"
	assert_equal "$result" 'from'
}
# bats test_tags=id:bash-043
@test "returns correct completion list: install jar from	-> file maven" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 4 "testcli" "install" "jar" "from")"
	assert_equal "$result" 'file maven' 
}
# bats test_tags=id:bash-044
@test "returns correct completion list: install war from	-> file maven" {
    load '../_helpers/auto-completion-mock-setup'
	result="$(test_completion 4 "testcli" "install" "war" "from")"
	assert_equal "$result" 'file maven' 
}
