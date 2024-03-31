setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
	ln -s ./audogombleed.sh ./testcli
	if [ ! -e "~/.testcli.conf" ]; then
		cp example.conf ~/.testcli.conf
	fi
}
teardown() {
	rm -rf ./testcli
	rm ~/.testcli.conf
}

@test "script runs without arguments" {
    run ./audogombleed.sh
	assert_line 'This script is not intended to be called directly.'
}

@test "can run our script with link" {
    run ./testcli
	assert_line 'no command supplied'
	assert_line $'execute \'testcli ?\' or \'testcli -h\' to display available commands'
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
