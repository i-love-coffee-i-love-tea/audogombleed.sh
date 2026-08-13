# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:bash

#
# Tests for global help header (bash)
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init __CLI_CFG_EXEC_SILENT="y"
    # install a dedicated test config with global header
    cp test/help-test-config.conf ~/.testcli.conf
}
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-257
@test "bash: global help header appears at top of output" {
    run ./testcli ?
    assert_success
    # header is the first line (index 0)
    assert_line --index 0 --partial "test CLI — comprehensive help text tests"
}

# bats test_tags=id:bash-258
@test "bash: global help header shows all lines" {
    run ./testcli ?
    assert_success
    assert_line --partial "test CLI — comprehensive help text tests"
    assert_line --partial "second header line"
}

# bats test_tags=id:bash-259
@test "bash: global help header appears before section headings" {
    run ./testcli ?
    assert_success
    local header_line section_line
    header_line=$(echo "$output" | grep -n "test CLI" | head -1 | cut -d: -f1)
    section_line=$(echo "$output" | grep -n "section alpha" | head -1 | cut -d: -f1)
    [ -n "$header_line" ]
    [ -n "$section_line" ]
    [ "$header_line" -lt "$section_line" ]
}

# bats test_tags=id:bash-260
@test "bash: global help header has 2-space indent" {
    run ./testcli ?
    assert_success
    assert_line "  test CLI — comprehensive help text tests"
    assert_line "  second header line"
}

# bats test_tags=id:bash-261
@test "bash: global help header does not appear in filtered command help" {
    run ./testcli alpha ?
    assert_success
    # filtered help shows sub-commands, not global header
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
    refute_line --partial "test CLI — comprehensive help text tests"
}

# bats test_tags=id:bash-262
@test "bash: no global header when config has none" {
    # use example.conf which has no global header
    cp example.conf ~/.testcli.conf
    run ./testcli ?
    assert_success
    # first line should be blank (before first section/command), not a header
    refute_line --partial "test CLI"
}

# bats test_tags=id:bash-263
@test "bash: # lines without blank line are section headings, not global header" {
    # config where # lines directly precede a command (no blank line)
    cat > ~/.testcli.conf <<'EOF'
[env]
__CLI_CFG_EXEC_SILENT="y"

[commands]
# first section
first
    one: echo one

# second section
second
    two: echo two
EOF
    run ./testcli ?
    assert_success
    # "first section" should be a section heading (2-space indent), not global header
    assert_line "  first section"
    assert_line "  second section"
    # commands should appear under their sections
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
}
