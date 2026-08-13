# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
# Tests -b/--batch mode (zsh)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

# bats test_tags=id:zsh-109
@test "zsh: batch mode executes command successfully" {
    run _zsh_run -b echo first second
    assert_success
    assert_output "second first"
}

# bats test_tags=id:zsh-110
@test "zsh: --batch long flag works same as -b" {
    run _zsh_run --batch echo first second
    assert_success
    assert_output "second first"
}

# bats test_tags=id:zsh-111
@test "zsh: batch mode returns correct exit code" {
    run _zsh_run -b return2
    assert_failure 2
}

# bats test_tags=id:zsh-112
@test "zsh: batch mode works with complex commands" {
    run _zsh_run -b install jar from file /some/file
    assert_success
    assert_output "/some/file"
}
