# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
# Tests argument placeholders \0, \1, \2 etc. (bash)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-165
@test "bash: \\0 is replaced by last command word" {
    # echo command uses \0 \2 \1 pattern
    run ./testcli echo first second third
    assert_success
    # \0=echo, \1=first, \2=second, \3=third -> \0 \2 \1 = echo second first
    # But remaining args (third) are appended
    assert_output "second first third"
}

# bats test_tags=id:bash-166
@test "bash: \\1 and \\2 are replaced by positional args" {
    run ./testcli echo alpha beta
    assert_success
    # \0=echo, \1=alpha, \2=beta -> echo beta alpha
    assert_output "beta alpha"
}

# bats test_tags=id:bash-167
@test "bash: extra args appended when not all placeholders used" {
    # echo uses \0 \2 \1, so with 3 args, the third is appended
    run ./testcli echo a b c
    assert_success
    assert_output "b a c"
}

# bats test_tags=id:bash-168
@test "bash: \\0 in install command replaces last word" {
    run ./testcli install jar from file /some/path
    assert_success
    assert_output "/some/path"
}

# bats test_tags=id:bash-169
@test "bash: placeholders work with maven coords" {
    run ./testcli install jar from maven coord123
    assert_success
    assert_output "coord123"
}
