# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
#	Tests "did you mean?" suggestions for unrecognized commands
#

setup_file()   { load '../_helpers/test-setup'; _test_init; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

@test "did you mean: typo suggests closest command" {
    run ./testcli deply
    assert_failure 51
    assert_line --partial "did you mean 'deploy'?"
}

@test "did you mean: transposed letters" {
    run ./testcli destory
    assert_failure 51
    assert_line --partial "did you mean 'destroy'?"
}

@test "did you mean: missing letter" {
    run ./testcli statux
    assert_failure 51
    assert_line --partial "did you mean 'status'?"
}

@test "did you mean: no suggestion for completely wrong input" {
    run ./testcli xyzzy
    assert_failure 51
    refute_line --partial "did you mean"
}

@test "did you mean: no suggestion for short input" {
    run ./testcli ab
    assert_failure 51
    refute_line --partial "did you mean"
}

@test "did you mean: still shows 'not a recognized command'" {
    run ./testcli deply
    assert_failure 51
    assert_line --partial "not a recognized command: 'deply'"
}
