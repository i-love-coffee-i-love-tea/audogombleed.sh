# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:fish

#
# Comprehensive tests for all help text types (fish)
#
# Tests:
#   - Global help (? / -h) shows section headings and all commands
#   - Section headings (# at top level before command groups)
#   - Command group help (command ?)
#   - Command help (# indented before a command)
#   - Standalone command help (# at top level before a leaf command)
#   - Detail help (## comments) — shown in both global and filtered help
#   - Bracket notation for minimum unambiguous prefix
#   - Argument placeholders in help output
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# --- global help ---

# bats test_tags=id:fish-281
@test "fish: global help shows section headings" {
    run _fish_run ?
    assert_success
    # section headings appear with 2-space indent
    assert_line "  section alpha"
    assert_line "  section beta"
}

# bats test_tags=id:fish-282
@test "fish: global help shows all commands with bracket notation" {
    run _fish_run ?
    assert_success
    assert_line --partial "a[lpha]"
    assert_line --partial "b[eta]"
    assert_line --partial "g[amma]"
    assert_line --partial "d[elta]"
}

# bats test_tags=id:fish-283
@test "fish: global help shows standalone command with inline help" {
    run _fish_run ?
    assert_success
    # standalone command: help is inline on the command line
    assert_line --partial "s[tandalone]"
    assert_line --partial "standalone command help"
    # NOT as a section heading (2-space prefix, separate line)
    refute_line "  standalone command help"
}

# bats test_tags=id:fish-284
@test "fish: global help shows sub-command help text inline" {
    run _fish_run ?
    assert_success
    # sub-command help appears inline with the command
    assert_line --partial "o[ne]"
    assert_line --partial "command under alpha"
    assert_line --partial "t[wo]"
    assert_line --partial "another command under alpha"
}

# bats test_tags=id:fish-285
@test "fish: global help shows detail comments below their command" {
    run _fish_run ?
    assert_success
    # ## detail comments appear in global help, after the command line
    assert_line --partial "detail line one for gamma four"
    assert_line --partial "detail line two for gamma four"
}

# bats test_tags=id:fish-286
@test "fish: global help shows group-level detail comments" {
    run _fish_run ?
    assert_success
    # ## group-level detail appears above the group's commands
    assert_line --partial "group detail line"
}

# --- section headings ---

# bats test_tags=id:fish-287
@test "fish: section heading appears above its command group in global help" {
    run _fish_run ?
    assert_success
    # section heading must appear before its group's commands
    local heading_line command_line
    heading_line=$(echo "$output" | grep -n "section alpha" | head -1 | cut -d: -f1)
    command_line=$(echo "$output" | grep -n "a\[lpha\]" | head -1 | cut -d: -f1)
    [ -n "$heading_line" ]
    [ -n "$command_line" ]
    [ "$heading_line" -lt "$command_line" ]
}

# bats test_tags=id:fish-288
@test "fish: section heading has 2-space indent (not inline with commands)" {
    run _fish_run ?
    assert_success
    # section headings are on their own line with "  " prefix
    assert_line "  section alpha"
    # commands have 6-space indent ("      ")
    refute_line "  section alpha o[ne]"
}

# --- command group help ---

# bats test_tags=id:fish-289
@test "fish: command group help shows sub-commands with bracket notation" {
    run _fish_run alpha ?
    assert_success
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
}

# --- standalone command help ---

# bats test_tags=id:fish-290
@test "fish: standalone command shows its own help when filtered" {
    run _fish_run standalone ?
    assert_success
    assert_line --partial "standalone command help"
}

# --- detail help (## comments) ---

# bats test_tags=id:fish-291
@test "fish: detail help shows for specific command" {
    run _fish_run gamma four ?
    assert_success
    assert_line --partial "detail line one for gamma four"
    assert_line --partial "detail line two for gamma four"
}

# bats test_tags=id:fish-292
@test "fish: detail help shows command help text" {
    run _fish_run gamma four ?
    assert_success
    assert_line --partial "command under gamma with details"
}

# bats test_tags=id:fish-293
@test "fish: command without details has no detail lines" {
    run _fish_run gamma five ?
    assert_success
    assert_line --partial "command under gamma without details"
    refute_line --partial "detail line"
}

# bats test_tags=id:fish-294
@test "fish: group-level ## detail shows in group help" {
    run _fish_run delta ?
    assert_success
    assert_line --partial "group detail line"
}

# --- bracket notation ---

# bats test_tags=id:fish-295
@test "fish: bracket notation marks minimum unambiguous prefix" {
    run _fish_run ?
    assert_success
    # 'a' is unique for alpha (no other top-level starts with 'a')
    assert_line --partial "a[lpha]"
    # 's' is unique for standalone
    assert_line --partial "s[tandalone]"
}

# bats test_tags=id:fish-296
@test "fish: sub-command bracket notation uses minimum prefix within group" {
    run _fish_run alpha ?
    assert_success
    # 'o' is unique for one (only sub-command starting with 'o')
    assert_line --partial "o[ne]"
    # 't' is unique for two (only sub-command starting with 't')
    assert_line --partial "t[wo]"
}

# --- argument placeholders ---

# bats test_tags=id:fish-297
@test "fish: help shows argument placeholders for commands with args" {
    # use the default example.conf for this test
    cp example.conf ~/.testcli.conf
    run _fish_run install -?
    assert_success
    assert_line --partial "<jar-file>"
    assert_line --partial "<mvn-coords>"
    assert_line --partial "<war-file>"
}
