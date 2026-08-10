# vim:et:ts=4:sw=4
# bats file_tags=category:integration, shell:zsh

#
# Tests for sourcing, completion registration, and shell detection (zsh)
#

setup_file() {
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load '../_helpers/common-teardown'
    _common_teardown
}
setup() {
    load '../_test_helper/bats-support/load'
    load '../_test_helper/bats-assert/load'
    load '../_helpers/zsh-helpers'
}

# bats test_tags=id:zsh-201
@test "zsh: direct execution exits 49" {
    run zsh ./audogombleed.sh
    assert_failure 49
}

# bats test_tags=id:zsh-202
@test "zsh: executes command with arguments" {
    run _zsh_run echo first second
    assert_success
    assert_line "second first"
}

# bats test_tags=id:zsh-203
@test "zsh: executes command with multiple arguments" {
    run _zsh_run echo first second third
    assert_success
    assert_line "second first third"
}

# bats test_tags=id:zsh-204
@test "zsh: sourcing registers _cli_execute function" {
    run zsh -c 'autoload -Uz compinit && compinit -u && source ./testcli && whence -f _cli_execute'
    assert_success
    assert_line --partial "_cli_execute"
}

# bats test_tags=id:zsh-205
@test "zsh: sourcing registers completions via compdef" {
    run zsh -c 'autoload -Uz compinit && compinit -u && source ./testcli && which _cli_complete_'
    assert_success
    assert_line --partial "_cli_complete_"
}

# bats test_tags=id:zsh-206
@test "zsh: shell detection returns true" {
    run zsh -c 'autoload -Uz compinit && compinit -u && source ./testcli && _cli_shell_is_zsh && echo "zsh detected"'
    assert_success
    assert_line "zsh detected"
}
