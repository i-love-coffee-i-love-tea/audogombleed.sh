# vim:et:ts=4:sw=4
# bats file_tags=category:completion, shell:fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# echo
@test "fish: returns correct completion list: echo -> first" {
	run _fish_eval '_cli_complete_arg 0 "" echo'
	assert_line "first"
}
@test "fish: returns correct completion list: echo first -> second" {
	run _fish_eval '_cli_complete_arg 1 "" echo'
	assert_line "second"
}

# var-expansion
@test "fish: returns correct completion list: var-expansion -> first second" {
	run _fish_eval '_cli_complete_command 2 var-expansion'
	assert_line "first"
	assert_line "second"
}
# function-expansion
@test "fish: returns correct completion list: function-expansion -> thievery corporation" {
	run _fish_eval '_cli_complete_command 2 function-expansion'
	assert_line "thievery"
	assert_line "corporation"
}
# list-expansion
@test "fish: returns correct completion list: list-expansion -> thievery corporation" {
	run _fish_eval '_cli_complete_command 2 list-expansion'
	assert_line "thievery"
	assert_line "corporation"
}

# list args
@test "fish: returns correct completion list: list-argument -> static from-function from-variable" {
	run _fish_eval '_cli_complete_command 2 list-argument'
	assert_line --partial "static"
	assert_line --partial "from-function"
	assert_line --partial "from-variable"
}
@test "fish: returns correct completion list: list-argument static -> first-element second third etc" {
	run _fish_eval '_cli_complete_arg 0 "" list-argument static'
	assert_line "first-element"
	assert_line "second"
	assert_line "third"
	assert_line "etc"
}
@test "fish: returns correct completion list: list-argument from-function -> opt1 opt2" {
	run _fish_eval '_cli_complete_arg 0 "" list-argument from-function'
	assert_line "opt1"
	assert_line "opt2"
}
@test "fish: returns correct completion list: list-argument from-variable -> option1 option2 option3" {
	run _fish_eval '_cli_complete_arg 0 "" list-argument from-variable'
	assert_line "option1"
	assert_line "option2"
	assert_line "option3"
}

# commands without args (tests the arg completion for commands without args)
@test "fish: returns empty completion for command without args: false" {
	run _fish_eval '_cli_complete_arg 0 "" false'
	assert_output ""
}
@test "fish: returns empty completion for command without args: return2" {
	run _fish_eval '_cli_complete_arg 0 "" return2'
	assert_output ""
}

# install
@test "fish: returns correct completion list: install -> jar war" {
	run _fish_eval '_cli_complete_command 2 install'
	assert_line "jar"
	assert_line "war"
}
@test "fish: returns correct completion list: install jar -> from" {
	run _fish_eval '_cli_complete_command 3 install jar'
	assert_line "from"
}
@test "fish: returns correct completion list: install war -> from" {
	run _fish_eval '_cli_complete_command 3 install war'
	assert_line "from"
}
@test "fish: returns correct completion list: install jar from -> file maven" {
	run _fish_eval '_cli_complete_command 4 install jar from'
	assert_line "file"
	assert_line "maven"
}
@test "fish: returns correct completion list: install war from -> file maven" {
	run _fish_eval '_cli_complete_command 4 install war from'
	assert_line "file"
	assert_line "maven"
}
