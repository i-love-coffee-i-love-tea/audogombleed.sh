# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish
#
# Tests argument placeholders \0, \1, \2 etc. under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: \\0 is replaced by last command word" {
    run _fish_run echo first second third
    assert_success
    # \0=echo, \1=first, \2=second, \3=third -> \0 \2 \1 = echo second first
    # But remaining args (third) are appended
    assert_output "second first third"
}

@test "fish: \\1 and \\2 are replaced by positional args" {
    run _fish_run echo alpha beta
    assert_success
    # \0=echo, \1=alpha, \2=beta -> echo beta alpha
    assert_output "beta alpha"
}

@test "fish: extra args appended when not all placeholders used" {
    run _fish_run echo a b c
    assert_success
    assert_output "b a c"
}

@test "fish: \\0 in install command replaces last word" {
    run _fish_run install jar from file /some/path
    assert_success
    assert_output "/some/path"
}

@test "fish: placeholders work with maven coords" {
    run _fish_run install jar from maven coord123
    assert_success
    assert_output "coord123"
}
