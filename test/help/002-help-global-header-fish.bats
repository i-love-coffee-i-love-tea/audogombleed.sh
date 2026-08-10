# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:fish
#
# Tests for global help header (fish)

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    cp test/help-test-config.conf ~/.testcli.conf
}
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: global help header appears at top of output" {
    run _fish_run ?
    assert_success
    assert_line --index 0 --partial "test CLI — comprehensive help text tests"
}

@test "fish: global help header shows all lines" {
    run _fish_run ?
    assert_success
    assert_line --partial "test CLI — comprehensive help text tests"
    assert_line --partial "second header line"
}

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

@test "fish: global help header has 2-space indent" {
    run _fish_run ?
    assert_success
    assert_line "  test CLI — comprehensive help text tests"
    assert_line "  second header line"
}

@test "fish: global help header does not appear in filtered command help" {
    run _fish_run alpha ?
    assert_success
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
    refute_line --partial "test CLI — comprehensive help text tests"
}

@test "fish: no global header when config has none" {
    cp example.conf ~/.testcli.conf
    run _fish_run ?
    assert_success
    refute_line --partial "test CLI"
}

@test "fish: # lines without blank line are section headings, not global header" {
    cat > ~/.testcli.conf <<'EOF'
[env.fish]
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
    assert_line "  first section"
    assert_line "  second section"
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
}
