# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
# Tests argument placeholders \0, \1, \2 etc. (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; cp "test/_configs/execution/003-argument-placeholders-fish.conf" ~/.testcli.conf; }

@test "fish: \\0 is replaced by last command word" {
    run _fish_run echo first second third
    assert_success
    assert_output "second first third"
}

@test "fish: \\1 and \\2 are replaced by positional args" {
    run _fish_run echo alpha beta
    assert_success
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
