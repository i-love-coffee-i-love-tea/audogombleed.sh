# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
#	Tests "did you mean?" suggestions for unrecognized commands (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: did you mean: typo suggests closest command" {
    run _fish_run deply
    assert_failure 51
    assert_line --partial "did you mean 'deploy'?"
}

@test "fish: did you mean: transposed letters" {
    run _fish_run destory
    assert_failure 51
    assert_line --partial "did you mean 'destroy'?"
}

@test "fish: did you mean: missing letter" {
    run _fish_run statux
    assert_failure 51
    assert_line --partial "did you mean 'status'?"
}

@test "fish: did you mean: no suggestion for completely wrong input" {
    run _fish_run xyzzy
    assert_failure 51
    refute_line --partial "did you mean"
}

@test "fish: did you mean: no suggestion for short input" {
    run _fish_run ab
    assert_failure 51
    refute_line --partial "did you mean"
}
