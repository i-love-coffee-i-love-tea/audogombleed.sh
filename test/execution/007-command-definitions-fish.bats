# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
#	Tests all possible command definition variations under fish
#   in silent mode
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    mkdir -p ~/bin
    echo '#!/bin/sh' > ~/bin/install-maven-war.sh
    echo 'echo "$@"' >> ~/bin/install-maven-war.sh
    chmod +x ~/bin/install-maven-war.sh
}
teardown_file() {
    load '../_helpers/test-setup'
    _test_cleanup
    rm -f ~/bin/install-maven-war.sh
}
setup()        { load '../_helpers/test-setup'; _test_load_fish; cp "test/_configs/execution/007-command-definitions-fish.conf" ~/.testcli.conf; }

@test "fish: executed without argument, returns exit code 50" {
    run fish -c 'set -g __CLI_CFG_EXEC_SILENT n; source ./testcli; _cli_execute 2>&1'
    assert_failure 50
}

@test "fish: can run command with positional argument placeholders" {
	run _fish_run echo first second third
	assert_output 'second first third'
}

@test "fish: can run command with variable expansion in command" {
	run _fish_run var-expansion first
	assert_output 'first'
}

@test "fish: can run command with function expansion in command" {
	run _fish_run function-expansion thievery --additional args
	assert_output 'thievery --additional args'
}

@test "fish: can run command with list expansion in command" {
	run _fish_run list-expansion corporation --additional args
	assert_output 'corporation --additional args'
}

@test "fish: can run command with static list argument" {
	run _fish_run list-argument static option1 more args
	assert_output 'option1 more args'
}

@test "fish: can run command with variable list argument" {
	run _fish_run list-argument from-variable option1 more args
	assert_output 'option1 more args'
}

@test "fish: can run command with function list argument" {
	run _fish_run list-argument from-function option1 more args
	assert_output 'option1 more args'
}

@test "fish: failing command returns correct exit status" {
	run _fish_run false
	assert_failure
}

@test "fish: arbitrary exit status is returned correctly" {
	run _fish_run return2
	assert_failure 2
}

@test "fish: complex tree structure commands are parsed correctly - 1" {
	run _fish_run install jar from file /some/file
	assert_output '/some/file'
}

@test "fish: complex tree structure commands are parsed correctly - 2" {
	run _fish_run install jar from maven _coords_
	assert_output '_coords_'
}

@test "fish: complex tree structure commands are parsed correctly - 3" {
	run _fish_run install war from file /some/file
	assert_output '/some/file'
}

@test "fish: complex tree structure commands are parsed correctly - 4" {
	run _fish_run install war from maven _coords_
	assert_output '_coords_'
}
