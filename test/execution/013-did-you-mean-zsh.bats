# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:zsh

#
#	Tests "did you mean?" suggestions for unrecognized commands (zsh)
#

setup_file()   { load '../_helpers/test-setup'; _test_init; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_zsh; }

@test "zsh: did you mean: typo suggests closest command" {
    run ./testcli deply
    assert_failure 51
    assert_line --partial "did you mean 'deploy'?"
}

@test "zsh: did you mean: transposed letters" {
    run ./testcli destory
    assert_failure 51
    assert_line --partial "did you mean 'destroy'?"
}

@test "zsh: did you mean: missing letter" {
    run ./testcli statux
    assert_failure 51
    assert_line --partial "did you mean 'status'?"
}

@test "zsh: did you mean: no suggestion for completely wrong input" {
    run ./testcli xyzzy
    assert_failure 51
    refute_line --partial "did you mean"
}

@test "zsh: did you mean: no suggestion for short input" {
    run ./testcli ab
    assert_failure 51
    refute_line --partial "did you mean"
}
