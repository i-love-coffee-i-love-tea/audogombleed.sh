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
}

# echo
@test "returns correct completion list: echo		-> first" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "echo")"
	assert_equal "$result" 'first' 
}
@test "returns correct completion list: echo first 		-> second" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "echo" "first")"
	assert_equal "$result" 'second' 
}

# var-expansion
@test "returns correct completion list: var-expansion	-> first second" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "var-expansion")"
	assert_equal "$result" 'first second' 
}
# function-expansion
@test "returns correct completion list: function-expansion	-> thievery corporation" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "function-expansion")"
	assert_equal "$result" 'thievery corporation' 
}
# list-expansion
@test "returns correct completion list: list-expansion	-> thievery corporation" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "list-expansion")"
	assert_equal "$result" 'thievery corporation' 
}

# list args
@test "returns correct completion list: list-argument	-> static from-function from-variable" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "list-argument")"
	assert_equal "$result" 'static from-function from-variable' 
}
@test "returns correct completion list: list-argument static -> first-element second third etc" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "list-argument" "static")"
	assert_equal "$result" 'first-element second third etc' 
}
@test "returns correct completion list: list-argument from-function -> opt1 opt2" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "list-argument" "from-function")"
	assert_equal "$result" 'opt1 opt2' 
}
@test "returns correct completion list: list-argument from-variable -> option1 option2 option3" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "list-argument" "from-variable")"
	assert_equal "$result" 'option1 option2 option3' 
}

# install
@test "returns correct completion list: install 		-> jar war" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 2 "testcli" "install")"
	assert_equal "$result" 'jar war' 
}
@test "returns correct completion list: install jar		-> from" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "install" "jar")"
	assert_equal "$result" 'from' 
}
@test "returns correct completion list: install war		-> from" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 3 "testcli" "install")"
	assert_equal "$result" 'from' 
}
@test "returns correct completion list: install jar from	-> file maven" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 4 "testcli" "install" "jar" "from")"
	assert_equal "$result" 'file maven' 
}
@test "returns correct completion list: install war from	-> file maven" {
    load 'auto-completion-mock-setup'
	result="$(test_completion 4 "testcli" "install" "war" "from")"
	assert_equal "$result" 'file maven' 
}
