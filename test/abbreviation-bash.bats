# vim:et:ts=4:sw=4

#
# Tests command abbreviation expansion (bash)
#

setup_file() {
    echo "# setup_file" >&3
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="n" __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS="n"
}
teardown_file() {
    echo "# teardown_file" >&3
    load 'common-teardown'
    _common_teardown
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
}

@test "bash: single-word abbreviation expands: e -> echo" {
    run ./testcli e first second
    assert_success
    assert_line --partial 'Executing command "echo"'
    assert_line "second first"
}

@test "bash: multi-word abbreviation expands: i j f m -> install jar from maven" {
    run ./testcli i j f m
    # Command expands and executes — the maven command runs ~/bin/install-maven-war.sh
    # which may or may not exist. The key assertion is that expansion happened.
    assert_line --partial 'Executing command "install jar from maven"'
}

@test "bash: abbreviation with args: i w f f -> install war from file" {
    run ./testcli i w f f /some/file
    assert_success
    assert_line --partial 'Executing command "install war from file"'
    assert_line "/some/file"
}

@test "bash: ambiguous abbreviation returns exit 51" {
    # 'i' is ambiguous between install and the echo/list commands
    # Use a config with truly ambiguous commands
    echo 'ambiguous-a: echo a' >> ~/.testcli.conf
    echo 'ambiguous-b: echo b' >> ~/.testcli.conf
    source ./testcli
    run ./testcli amb
    assert_failure 51
}

@test "bash: unrecognized abbreviation returns exit 51" {
    run ./testcli nonexistent
    assert_failure 51
}

@test "bash: abbreviation disabled by CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS=n" {
    load 'common-setup'
    _set_option __CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS '"n"'
    source ./testcli
    run ./testcli e first second
    assert_failure 51
}

@test "bash: abbreviation disabled in batch mode" {
    run ./testcli -b e first second
    assert_failure 51
}
