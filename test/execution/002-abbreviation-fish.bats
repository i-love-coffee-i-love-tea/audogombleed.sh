# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:fish

#
# Tests command abbreviation expansion (fish)
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file() { set +e; rm -f ./testcli ~/.testcli.conf 2>/dev/null; true; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: single-word abbreviation expands: e -> echo" {
    run _fish_run e first second
    assert_success
    assert_line --partial 'Executing command "echo"'
    assert_line "second first"
}

@test "fish: multi-word abbreviation expands: i j f m -> install jar from maven" {
    run _fish_run i j f m coord123
    assert_line --partial 'Executing command "install jar from maven"'
}

@test "fish: abbreviation with args: i w f f -> install war from file" {
    run _fish_run i w f f /some/file
    assert_success
    assert_line --partial 'Executing command "install war from file"'
    assert_line "/some/file"
}

@test "fish: ambiguous abbreviation returns exit 51" {
    echo 'ambiguous-a: echo a' >> ~/.testcli.conf
    echo 'ambiguous-b: echo b' >> ~/.testcli.conf
    run _fish_run amb
    assert_failure 51
}

@test "fish: unrecognized abbreviation returns exit 51" {
    run _fish_run nonexistent
    assert_failure 51
}

@test "fish: abbreviation disabled by CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS=n" {
    _set_option __CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS '"n"'
    run _fish_run e first second
    assert_failure 51
}

@test "fish: abbreviation disabled in batch mode" {
    run _fish_run -b e first second
    assert_failure 51
}

@test "fish: no-space abbreviation expands: ijfm -> install jar from maven" {
    run _fish_run ijfm coord123
    assert_line --partial 'Executing command "install jar from maven"'
}

@test "fish: no-space abbreviation expands: iwff -> install war from file" {
    run _fish_run iwff /some/file
    assert_success
    assert_line --partial 'Executing command "install war from file"'
    assert_line "/some/file"
}

@test "fish: no-space abbreviation expands: ijff -> install jar from file" {
    run _fish_run ijff /some/file
    assert_success
    assert_line --partial 'Executing command "install jar from file"'
    assert_line "/some/file"
}

@test "fish: no-space abbreviation ambiguous returns exit 51" {
    echo 'ambiguous-a: echo a' >> ~/.testcli.conf
    echo 'ambiguous-b: echo b' >> ~/.testcli.conf
    run _fish_run amb
    assert_failure 51
}

@test "fish: no-space abbreviation disabled by CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS=n" {
    _set_option __CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS '"n"'
    run _fish_run ijfm coord123
    assert_failure 51
}
