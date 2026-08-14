# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:zsh

#
# Zsh tab completion tests.
# Zsh completions include [description] suffixes from config # comments and arg types.
# Output is one completion per line.

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }

# echo — arg type "list" gets [one of the following] description
# bats test_tags=id:zsh-013
@test "zsh: echo completion -> first" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "echo"
	assert_line "first[one of the following]"
}
# bats test_tags=id:zsh-014
@test "zsh: echo first completion -> second" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "echo" "first"
	assert_line "second[one of the following]"
}

# var-expansion
# bats test_tags=id:zsh-015
@test "zsh: var-expansion completion includes description" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "var-expansion"
	assert_line "first"
	assert_line "second"
}

# function-expansion
# bats test_tags=id:zsh-016
@test "zsh: function-expansion completion includes description" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "function-expansion"
	assert_line "thievery"
	assert_line "corporation"
}

# list-expansion
# bats test_tags=id:zsh-017
@test "zsh: list-expansion completion" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "list-expansion"
	assert_line "thievery"
	assert_line "corporation"
}

# list args — first word (with descriptions)
# bats test_tags=id:zsh-018
@test "zsh: list-argument first-word completion" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "list-argument"
	assert_line --partial "static"
	assert_line --partial "from-function"
	assert_line --partial "from-variable"
}

# list args — static list with [description]
# bats test_tags=id:zsh-019
@test "zsh: list-argument static -> elements with description" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "list-argument" "static"
	assert_line "first-element[one of the following]"
	assert_line "second[one of the following]"
	assert_line "third[one of the following]"
	assert_line "etc[one of the following]"
}

# list args — from-function (eval type, no description suffix)
# bats test_tags=id:zsh-020
@test "zsh: list-argument from-function -> opt1 opt2" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "list-argument" "from-function"
	assert_line "opt1"
	assert_line "opt2"
}

# list args — from-variable
@test "zsh: list-argument from-variable -> option1 option2 option3" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "list-argument" "from-variable"
	assert_line --partial "option1"
	assert_line --partial "option2"
	assert_line --partial "option3"
}

# commands without args
# bats test_tags=id:zsh-021
@test "zsh: returns empty completion for command without args: false" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "false"
	assert_output ""
}
# bats test_tags=id:zsh-022
@test "zsh: returns empty completion for command without args: return2" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "return2"
	assert_output ""
}

# install — first word
# bats test_tags=id:zsh-023
@test "zsh: install first-word completion" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "install"
	assert_line "jar"
	assert_line "war"
}

# bats test_tags=id:zsh-024
@test "zsh: install jar -> from" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "install" "jar"
	assert_line "from"
}

# bats test_tags=id:zsh-025
@test "zsh: install war -> from" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "install" "war"
	assert_line "from"
}

# bats test_tags=id:zsh-026
@test "zsh: install jar from -> file maven" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 5 "testcli" "install" "jar" "from"
	assert_line "file"
	assert_line "maven"
}

# bats test_tags=id:zsh-027
@test "zsh: install war from -> file maven" {
    load '../_helpers/auto-completion-mock-setup-zsh'
	run test_completion_zsh 5 "testcli" "install" "war" "from"
	assert_line "file"
	assert_line "maven"
}
