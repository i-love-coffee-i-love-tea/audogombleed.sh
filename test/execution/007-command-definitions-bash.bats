# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
#	Tests all possible command definition variations
#   in silent mode	
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init __CLI_CFG_EXEC_SILENT="y"
    # Create dummy script for maven commands
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
setup()        { load '../_helpers/test-setup'; _test_load_bash; }


# bats test_tags=id:bash-185
@test "directly executed, it displays a message and exits" {
    run ./derakht.sh
	assert_line 'This script is not intended to be called directly.'
}

# bats test_tags=id:bash-186
@test "executed without argument, returns exit code 50 and doesn't print anything" {
    run env __CLI_testcli_CFG_EXEC_SILENT="n" ./testcli
	assert_failure 50 
	assert_output ""  
#	assert_line 'no command supplied'
#	assert_line $'execute \'testcli ?\' or \'testcli -h\' to display available commands'
}

# bats test_tags=id:bash-187
@test "can run command with positional argument placeholders" {
	run ./testcli echo first second third
	assert_output 'second first third'
}

# bats test_tags=id:bash-188
@test "can run command with variable expansion in command" {
	run ./testcli var-expansion first
	assert_output 'first'
}

# bats test_tags=id:bash-189
@test "can run command with function expansion in command" {
	run ./testcli function-expansion thievery --additional args
	assert_output 'thievery --additional args'
}

# bats test_tags=id:bash-190
@test "can run command with list expansion in command" {
	run ./testcli list-expansion corporation --additional args
	assert_output 'corporation --additional args'
}

# bats test_tags=id:bash-191
@test "can run command with static list argument" {
	run ./testcli list-argument static option1 more args
	assert_output 'option1 more args'
}
# bats test_tags=id:bash-192
@test "can run command with variable list argument" {
	run ./testcli list-argument from-variable option1 more args
	assert_output 'option1 more args'
}
# bats test_tags=id:bash-193
@test "can run command with function list argument" {
	run ./testcli list-argument from-function option1 more args
	assert_output 'option1 more args'
}

# bats test_tags=id:bash-194
@test "failing command returns correct exit status" {
	run ./testcli false
	assert_failure
}
# bats test_tags=id:bash-195
@test "arbitrary exit status is returned correctly" {
	run ./testcli return2
	assert_failure 2
}
# bats test_tags=id:bash-196
@test "complex tree structure commands are parsed correctly - 1" {
	run ./testcli install jar from file /some/file
	assert_output '/some/file'
}
# bats test_tags=id:bash-197
@test "complex tree structure commands are parsed correctly - 2" {
	run ./testcli install jar from maven _coords_
	assert_output '_coords_'
}
# bats test_tags=id:bash-198
@test "complex tree structure commands are parsed correctly - 3" {
	run ./testcli install war from file /some/file
	assert_output '/some/file'
}
# bats test_tags=id:bash-199
@test "complex tree structure commands are parsed correctly - 4" {
	run ./testcli install war from maven _coords_
	assert_output '_coords_'
}

