# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish
#
# Tests batch mode (-b/--batch) under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: batch mode -b flag works" {
    run _fish_run -b echo first second third
    assert_success
    assert_output "second first third"
}

@test "fish: batch mode --batch flag works" {
    run _fish_run --batch echo first second third
    assert_success
    assert_output "second first third"
}

@test "fish: abbreviation disabled in batch mode" {
    run _fish_run -b e first second
    assert_failure 51
}

@test "fish: batch mode with complex command" {
    run _fish_run -b install jar from file /some/file
    assert_success
    assert_output "/some/file"
}
