# vim:et:ts=4:sw=4

#
# Zsh tab completion tests.
# Zsh completions include [description] suffixes from config # comments and arg types.
# Output is one completion per line.

setup_file() {
  	echo "# setup_file" >&3
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
  	echo "# teardown_file" >&3
    load 'common-teardown'
    _common_teardown
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'zsh-helpers'
}

# echo — arg type "list" gets [one of the following] description
@test "zsh: echo completion -> first" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "echo"
	assert_line "first[one of the following]"
}
@test "zsh: echo first completion -> second" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "echo" "first"
	assert_line "second[one of the following]"
}

# var-expansion
@test "zsh: var-expansion completion includes description" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "var-expansion"
	assert_line "first"
	assert_line "second"
}

# function-expansion
@test "zsh: function-expansion completion includes description" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "function-expansion"
	assert_line "thievery"
	assert_line "corporation"
}

# list-expansion
@test "zsh: list-expansion completion" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "list-expansion"
	assert_line "thievery"
	assert_line "corporation"
}

# list args — first word
@test "zsh: list-argument first-word completion" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "list-argument"
	assert_line "static"
	assert_line "from-function"
	assert_line "from-variable"
}

# list args — static list with [description]
@test "zsh: list-argument static -> elements with description" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "list-argument" "static"
	echo "# actual output: ${lines[*]}" >&3
	assert_line "first-element[one of the following]"
	assert_line "second[one of the following]"
	assert_line "third[one of the following]"
	assert_line "etc[one of the following]"
}

# list args — from-function (eval type, no description suffix)
@test "zsh: list-argument from-function -> opt1 opt2" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "list-argument" "from-function"
	assert_line "opt1"
	assert_line "opt2"
}

# commands without args
@test "zsh: returns empty completion for command without args: false" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "false"
	assert_output ""
}
@test "zsh: returns empty completion for command without args: return2" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "return2"
	assert_output ""
}

# install — first word
@test "zsh: install first-word completion" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 3 "testcli" "install"
	assert_line "jar"
	assert_line "war"
}

@test "zsh: install jar -> from" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "install" "jar"
	assert_line "from"
}

@test "zsh: install war -> from" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 4 "testcli" "install" "war"
	assert_line "from"
}

@test "zsh: install jar from -> file maven" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 5 "testcli" "install" "jar" "from"
	assert_line "file"
	assert_line "maven"
}

@test "zsh: install war from -> file maven" {
    load 'auto-completion-mock-setup-zsh'
	run test_completion_zsh 5 "testcli" "install" "war" "from"
	assert_line "file"
	assert_line "maven"
}
