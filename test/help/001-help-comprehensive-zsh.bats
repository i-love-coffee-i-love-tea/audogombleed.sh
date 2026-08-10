# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:zsh

#
# Comprehensive tests for all help text types (zsh)
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

setup_file() {
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"

    # install a dedicated test config with all help text types
    cp test/help-test-config.conf ~/.testcli.conf
}
teardown_file() {
    load '../_helpers/common-teardown'
    _common_teardown
}
setup() {
    load '../_test_helper/bats-support/load'
    load '../_test_helper/bats-assert/load'
    load '../_helpers/zsh-helpers'
}

# --- global help ---

# bats test_tags=id:zsh-165
@test "zsh: global help shows section headings" {
    run _zsh_run ?
    assert_success
    # section headings appear with 2-space indent
    assert_line "  section alpha"
    assert_line "  section beta"
}

# bats test_tags=id:zsh-166
@test "zsh: global help shows all commands with bracket notation" {
    run _zsh_run ?
    assert_success
    assert_line --partial "a[lpha]"
    assert_line --partial "b[eta]"
    assert_line --partial "g[amma]"
    assert_line --partial "d[elta]"
}

# bats test_tags=id:zsh-167
@test "zsh: global help shows standalone command with inline help" {
    run _zsh_run ?
    assert_success
    # standalone command: help is inline on the command line
    assert_line --partial "s[tandalone]"
    assert_line --partial "standalone command help"
    # NOT as a section heading (2-space prefix, separate line)
    refute_line "  standalone command help"
}

# bats test_tags=id:zsh-168
@test "zsh: global help shows sub-command help text inline" {
    run _zsh_run ?
    assert_success
    # sub-command help appears inline with the command
    assert_line --partial "o[ne]"
    assert_line --partial "command under alpha"
    assert_line --partial "t[wo]"
    assert_line --partial "another command under alpha"
}

# bats test_tags=id:zsh-169
@test "zsh: global help shows detail comments below their command" {
    run _zsh_run ?
    assert_success
    # ## detail comments appear in global help, after the command line
    assert_line --partial "detail line one for gamma four"
    assert_line --partial "detail line two for gamma four"
}

# bats test_tags=id:zsh-170
@test "zsh: global help shows group-level detail comments" {
    run _zsh_run ?
    assert_success
    # ## group-level detail appears above the group's commands
    assert_line --partial "group detail line"
}

# --- section headings ---

# bats test_tags=id:zsh-171
@test "zsh: section heading appears above its command group in global help" {
    run _zsh_run ?
    assert_success
    # section heading must appear before its group's commands
    local heading_line command_line
    heading_line=$(echo "$output" | grep -n "section alpha" | head -1 | cut -d: -f1)
    command_line=$(echo "$output" | grep -n "a\[lpha\]" | head -1 | cut -d: -f1)
    [ -n "$heading_line" ]
    [ -n "$command_line" ]
    [ "$heading_line" -lt "$command_line" ]
}

# bats test_tags=id:zsh-172
@test "zsh: section heading has 2-space indent (not inline with commands)" {
    run _zsh_run ?
    assert_success
    # section headings are on their own line with "  " prefix
    assert_line "  section alpha"
    # commands have 6-space indent ("      ")
    refute_line "  section alpha o[ne]"
}

# --- command group help ---

# bats test_tags=id:zsh-173
@test "zsh: command group help shows sub-commands with bracket notation" {
    run _zsh_run alpha ?
    assert_success
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
}

# --- standalone command help ---

# bats test_tags=id:zsh-174
@test "zsh: standalone command shows its own help when filtered" {
    run _zsh_run standalone ?
    assert_success
    assert_line --partial "standalone command help"
}

# --- detail help (## comments) ---

# bats test_tags=id:zsh-175
@test "zsh: detail help shows for specific command" {
    run _zsh_run gamma four ?
    assert_success
    assert_line --partial "detail line one for gamma four"
    assert_line --partial "detail line two for gamma four"
}

# bats test_tags=id:zsh-176
@test "zsh: detail help shows command help text" {
    run _zsh_run gamma four ?
    assert_success
    assert_line --partial "command under gamma with details"
}

# bats test_tags=id:zsh-177
@test "zsh: command without details has no detail lines" {
    run _zsh_run gamma five ?
    assert_success
    assert_line --partial "command under gamma without details"
    refute_line --partial "detail line"
}

# bats test_tags=id:zsh-178
@test "zsh: group-level ## detail shows in group help" {
    run _zsh_run delta ?
    assert_success
    assert_line --partial "group detail line"
}

# --- bracket notation ---

# bats test_tags=id:zsh-179
@test "zsh: bracket notation marks minimum unambiguous prefix" {
    run _zsh_run ?
    assert_success
    # 'a' is unique for alpha (no other top-level starts with 'a')
    assert_line --partial "a[lpha]"
    # 's' is unique for standalone
    assert_line --partial "s[tandalone]"
}

# bats test_tags=id:zsh-180
@test "zsh: sub-command bracket notation uses minimum prefix within group" {
    run _zsh_run alpha ?
    assert_success
    # 'o' is unique for one (only sub-command starting with 'o')
    assert_line --partial "o[ne]"
    # 't' is unique for two (only sub-command starting with 't')
    assert_line --partial "t[wo]"
}

# --- argument placeholders ---

# bats test_tags=id:zsh-181
@test "zsh: help shows argument placeholders for commands with args" {
    # use the default example.conf for this test
    cp example.conf ~/.testcli.conf
    run _zsh_run install -?
    assert_success
    assert_line --partial "<jar-file>"
    assert_line --partial "<mvn-coords>"
    assert_line --partial "<war-file>"
}
