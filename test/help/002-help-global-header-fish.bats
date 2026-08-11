# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:fish

#
# Tests for global help header (fish)
#

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    # install a dedicated test config with global header
    cp test/help-test-config.conf ~/.testcli.conf
}
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; cp "test/_configs/help/002-help-global-header-fish.conf" ~/.testcli.conf; }

# bats test_tags=id:fish-298
@test "fish: global help header appears at top of output" {
    run _fish_run ?
    assert_success
    # header is the first line (index 0)
    assert_line --index 0 --partial "test CLI — comprehensive help text tests"
}

# bats test_tags=id:fish-299
@test "fish: global help header shows all lines" {
    run _fish_run ?
    assert_success
    assert_line --partial "test CLI — comprehensive help text tests"
    assert_line --partial "second header line"
}

# bats test_tags=id:fish-300
@test "fish: global help header appears before section headings" {
    run _fish_run ?
    assert_success
    local header_line section_line
    header_line=$(echo "$output" | grep -n "test CLI" | head -1 | cut -d: -f1)
    section_line=$(echo "$output" | grep -n "section alpha" | head -1 | cut -d: -f1)
    [ -n "$header_line" ]
    [ -n "$section_line" ]
    [ "$header_line" -lt "$section_line" ]
}

# bats test_tags=id:fish-301
@test "fish: global help header has 2-space indent" {
    run _fish_run ?
    assert_success
    assert_line "  test CLI — comprehensive help text tests"
    assert_line "  second header line"
}

# bats test_tags=id:fish-302
@test "fish: global help header does not appear in filtered command help" {
    run _fish_run alpha ?
    assert_success
    # filtered help shows sub-commands, not global header
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
    refute_line --partial "test CLI — comprehensive help text tests"
}

# bats test_tags=id:fish-303
@test "fish: no global header when config has none" {
    # use example.conf which has no global header
    cp example.conf ~/.testcli.conf
    run _fish_run ?
    assert_success
    # first line should be blank (before first section/command), not a header
    refute_line --partial "test CLI"
}

# bats test_tags=id:fish-304
@test "fish: # lines without blank line are section headings, not global header" {
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
    run _fish_run ?
    assert_success
    # "first section" should be a section heading (2-space indent), not global header
    assert_line "  first section"
    assert_line "  second section"
    # commands should appear under their sections
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
}
