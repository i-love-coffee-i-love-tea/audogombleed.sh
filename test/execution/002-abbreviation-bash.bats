# vim:et:ts=4:sw=4
# bats file_tags=category:execution, shell:bash

#
# Tests command abbreviation expansion (bash)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="n" __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-159
@test "bash: single-word abbreviation expands: e -> echo" {
    run ./testcli e first second
    assert_success
    assert_line --partial 'Executing command "echo"'
    assert_line "second first"
}

# bats test_tags=id:bash-160
@test "bash: multi-word abbreviation expands: i j f m -> install jar from maven" {
    run ./testcli i j f m coord123
    # Command expands and executes — the maven command runs ~/bin/install-maven-war.sh
    # which may or may not exist. The key assertion is that expansion happened.
    assert_line --partial 'Executing command "install jar from maven"'
}

# bats test_tags=id:bash-161
@test "bash: abbreviation with args: i w f f -> install war from file" {
    run ./testcli i w f f /some/file
    assert_success
    assert_line --partial 'Executing command "install war from file"'
    assert_line "/some/file"
}

# bats test_tags=id:bash-162
@test "bash: ambiguous abbreviation returns exit 51" {
    # 'i' is ambiguous between install and the echo/list commands
    # Use a config with truly ambiguous commands
    echo 'ambiguous-a: echo a' >> ~/.testcli.conf
    echo 'ambiguous-b: echo b' >> ~/.testcli.conf
    source ./testcli
    run ./testcli amb
    assert_failure 51
}

# bats test_tags=id:bash-163
@test "bash: unrecognized abbreviation returns exit 51" {
    run ./testcli nonexistent
    assert_failure 51
}

# bats test_tags=id:bash-164
@test "bash: abbreviation disabled by CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS=n" {
    load '../_helpers/common-setup'
    _set_option __CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS '"n"'
    source ./testcli
    run ./testcli e first second
    assert_failure 51
}

# bats test_tags=id:bash-165
@test "bash: abbreviation disabled in batch mode" {
    run ./testcli -b e first second
    assert_failure 51
}
