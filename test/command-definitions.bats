#
#	Tests all possible command definition variations
#   in silent mode	
#

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load 'common-teardown'
    _common_teardown
}
setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
}


@test "directly executed, it displays a message and exits" {
    run ./audogombleed.sh
	assert_line 'This script is not intended to be called directly.'
}

@test "executed without argument, returns exit code 50 and doesn't print anything" {
    run env __CLI_testcli_CFG_EXEC_SILENT="n" ./testcli
	assert_failure 50 
	assert_output ""  
#	assert_line 'no command supplied'
#	assert_line $'execute \'testcli ?\' or \'testcli -h\' to display available commands'
}

@test "can run command with positional argument placeholders" {
	run ./testcli echo first second third
	assert_output 'echo second first third'
}

@test "can run command with variable expansion in command" {
	run ./testcli var-expansion first
	assert_output 'first'
}

@test "can run command with function expansion in command" {
	run ./testcli function-expansion thievery --additional args
	assert_output 'thievery --additional args'
}

@test "can run command with list expansion in command" {
	run ./testcli list-expansion corporation --additional args
	assert_output 'corporation --additional args'
}

@test "can run command with static list argument" {
	run ./testcli list-argument static option1 more args
	assert_output 'option1 more args'
}
@test "can run command with variable list argument" {
	run ./testcli list-argument from-variable option1 more args
	assert_output 'option1 more args'
}
@test "can run command with function list argument" {
	run ./testcli list-argument from-function option1 more args
	assert_output 'option1 more args'
}

@test "failing command returns correct exit status" {
	run ./testcli false
	assert_failure
}
@test "arbitray exit status is returned correctly" {
	run ./testcli return2
	assert_failure 2
}
@test "complex tree structure commands are parsed correctly - 1" {
	run ./testcli install jar from file /some/file
	assert_output '/some/file'
}
@test "complex tree structure commands are parsed correctly - 2" {
	run ./testcli install jar from maven _coords_
	assert_output '_coords_'
}
@test "complex tree structure commands are parsed correctly - 3" {
	run ./testcli install war from file /some/file
	assert_output '/some/file'
}
@test "complex tree structure commands are parsed correctly - 4" {
	run ./testcli install war from file _coords_
	assert_output '_coords_'
}

