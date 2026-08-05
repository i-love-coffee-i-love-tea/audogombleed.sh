# vim:et:ts=4:sw=4

#
# Tests argument placeholders \0, \1, \2 etc. (zsh)
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
    load 'zsh-helpers'
}

@test "zsh: \\0 is replaced by last command word" {
    run _zsh_run echo first second third
    assert_success
    assert_output "second first third"
}

@test "zsh: \\1 and \\2 are replaced by positional args" {
    run _zsh_run echo alpha beta
    assert_success
    assert_output "beta alpha"
}

@test "zsh: extra args appended when not all placeholders used" {
    run _zsh_run echo a b c
    assert_success
    assert_output "b a c"
}

@test "zsh: \\0 in install command replaces last word" {
    run _zsh_run install jar from file /some/path
    assert_success
    assert_output "/some/path"
}

@test "zsh: placeholders work with maven coords" {
    run _zsh_run install jar from maven coord123
    assert_success
    assert_output "coord123"
}
