# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
# Tests -b/--batch mode (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: batch mode executes command successfully" {
    run _fish_run -b echo first second
    assert_success
    assert_output "second first"
}

@test "fish: --batch long flag works same as -b" {
    run _fish_run --batch echo first second
    assert_success
    assert_output "second first"
}

@test "fish: batch mode disables abbreviation expansion" {
    run _fish_run -b e first second
    assert_failure 51
}

@test "fish: batch mode returns correct exit code" {
    run _fish_run -b return2
    assert_failure 2
}

@test "fish: batch mode works with complex commands" {
    run _fish_run -b install jar from file /some/file
    assert_success
    assert_output "/some/file"
}
