# vim:et:ts=4:sw=4

#
# Tests all possible command definition variations under zsh
#

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
    # Create dummy script for maven commands
    mkdir -p ~/bin
    echo '#!/bin/sh' > ~/bin/install-maven-war.sh
    echo 'echo "$@"' >> ~/bin/install-maven-war.sh
    chmod +x ~/bin/install-maven-war.sh
}
teardown_file() {
    load 'common-teardown'
    _common_teardown
    rm -f ~/bin/install-maven-war.sh
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'zsh-helpers'
}

@test "zsh: directly executed, displays usage message" {
    run zsh ./audogombleed.sh
    assert_line 'This script is not intended to be called directly.'
}

@test "zsh: no argument returns exit code 50" {
    run _zsh_run
    assert_failure 50
}

@test "zsh: can run command with positional argument placeholders" {
    run _zsh_run echo first second third
    assert_output 'second first third'
}

@test "zsh: can run command with variable expansion in command" {
    run _zsh_run var-expansion first
    assert_output 'first'
}

@test "zsh: can run command with function expansion in command" {
    run _zsh_run function-expansion thievery --additional args
    assert_output 'thievery --additional args'
}

@test "zsh: can run command with list expansion in command" {
    run _zsh_run list-expansion corporation --additional args
    assert_output 'corporation --additional args'
}

@test "zsh: can run command with static list argument" {
    run _zsh_run list-argument static option1 more args
    assert_output 'option1 more args'
}

@test "zsh: can run command with variable list argument" {
    run _zsh_run list-argument from-variable option1 more args
    assert_output 'option1 more args'
}

@test "zsh: can run command with function list argument" {
    run _zsh_run list-argument from-function option1 more args
    assert_output 'option1 more args'
}

@test "zsh: failing command returns correct exit status" {
    run _zsh_run false
    assert_failure
}

@test "zsh: arbitrary exit status is returned correctly" {
    run _zsh_run return2
    assert_failure 2
}

@test "zsh: complex tree structure commands are parsed correctly - 1" {
    run _zsh_run install jar from file /some/file
    assert_output '/some/file'
}

@test "zsh: complex tree structure commands are parsed correctly - 2" {
    run _zsh_run install jar from maven _coords_
    assert_output '_coords_'
}

@test "zsh: complex tree structure commands are parsed correctly - 3" {
    run _zsh_run install war from file /some/file
    assert_output '/some/file'
}

@test "zsh: complex tree structure commands are parsed correctly - 4" {
    run _zsh_run install war from maven _coords_
    assert_output '_coords_'
}

@test "zsh: unrecognized command returns exit code 51" {
    run _zsh_run nonexistent
    assert_failure 51
}

@test "zsh: help trigger shows commands" {
    run _zsh_run ?
    assert_success
    assert_line --partial '[cho]'
    assert_line --partial '[nstall]'
}
