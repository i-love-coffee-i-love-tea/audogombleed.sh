# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
# Tests argument placeholders \0, \1, \2 etc. (zsh)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-103
@test "zsh: \\0 is replaced by last command word" {
    run _zsh_run echo first second third
    assert_success
    assert_output "second first third"
}

# bats test_tags=id:zsh-104
@test "zsh: \\1 and \\2 are replaced by positional args" {
    run _zsh_run echo alpha beta
    assert_success
    assert_output "beta alpha"
}

# bats test_tags=id:zsh-105
@test "zsh: extra args appended when not all placeholders used" {
    run _zsh_run echo a b c
    assert_success
    assert_output "b a c"
}

# bats test_tags=id:zsh-106
@test "zsh: \\0 in install command replaces last word" {
    run _zsh_run install jar from file /some/path
    assert_success
    assert_output "/some/path"
}

# bats test_tags=id:zsh-107
@test "zsh: placeholders work with maven coords" {
    run _zsh_run install jar from maven coord123
    assert_success
    assert_output "coord123"
}
