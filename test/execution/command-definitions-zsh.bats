# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
# Tests all possible command definition variations under zsh
#

setup_file() {
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
    # Create dummy script for maven commands
    mkdir -p ~/bin
    echo '#!/bin/sh' > ~/bin/install-maven-war.sh
    echo 'echo "$@"' >> ~/bin/install-maven-war.sh
    chmod +x ~/bin/install-maven-war.sh
}
teardown_file() {
    load '../_helpers/common-teardown'
    _common_teardown
    rm -f ~/bin/install-maven-war.sh
}
setup() {
    load '../_test_helper/bats-support/load'
    load '../_test_helper/bats-assert/load'
    load '../_helpers/zsh-helpers'
}

# bats test_tags=id:zsh-121
@test "zsh: directly executed, displays usage message" {
    run zsh ./audogombleed.sh
    assert_line 'This script is not intended to be called directly.'
}

# bats test_tags=id:zsh-122
@test "zsh: no argument returns exit code 50" {
    run _zsh_run
    assert_failure 50
}

# bats test_tags=id:zsh-123
@test "zsh: can run command with positional argument placeholders" {
    run _zsh_run echo first second third
    assert_output 'second first third'
}

# bats test_tags=id:zsh-124
@test "zsh: can run command with variable expansion in command" {
    run _zsh_run var-expansion first
    assert_output 'first'
}

# bats test_tags=id:zsh-125
@test "zsh: can run command with function expansion in command" {
    run _zsh_run function-expansion thievery --additional args
    assert_output 'thievery --additional args'
}

# bats test_tags=id:zsh-126
@test "zsh: can run command with list expansion in command" {
    run _zsh_run list-expansion corporation --additional args
    assert_output 'corporation --additional args'
}

# bats test_tags=id:zsh-127
@test "zsh: can run command with static list argument" {
    run _zsh_run list-argument static option1 more args
    assert_output 'option1 more args'
}

# bats test_tags=id:zsh-128
@test "zsh: can run command with variable list argument" {
    run _zsh_run list-argument from-variable option1 more args
    assert_output 'option1 more args'
}

# bats test_tags=id:zsh-129
@test "zsh: can run command with function list argument" {
    run _zsh_run list-argument from-function option1 more args
    assert_output 'option1 more args'
}

# bats test_tags=id:zsh-130
@test "zsh: failing command returns correct exit status" {
    run _zsh_run false
    assert_failure
}

# bats test_tags=id:zsh-131
@test "zsh: arbitrary exit status is returned correctly" {
    run _zsh_run return2
    assert_failure 2
}

# bats test_tags=id:zsh-132
@test "zsh: complex tree structure commands are parsed correctly - 1" {
    run _zsh_run install jar from file /some/file
    assert_output '/some/file'
}

# bats test_tags=id:zsh-133
@test "zsh: complex tree structure commands are parsed correctly - 2" {
    run _zsh_run install jar from maven _coords_
    assert_output '_coords_'
}

# bats test_tags=id:zsh-134
@test "zsh: complex tree structure commands are parsed correctly - 3" {
    run _zsh_run install war from file /some/file
    assert_output '/some/file'
}

# bats test_tags=id:zsh-135
@test "zsh: complex tree structure commands are parsed correctly - 4" {
    run _zsh_run install war from maven _coords_
    assert_output '_coords_'
}

# bats test_tags=id:zsh-136
@test "zsh: unrecognized command returns exit code 51" {
    run _zsh_run nonexistent
    assert_failure 51
}

# bats test_tags=id:zsh-137
@test "zsh: help trigger shows commands" {
    run _zsh_run ?
    assert_success
    assert_line --partial '[cho]'
    assert_line --partial '[nstall]'
}
