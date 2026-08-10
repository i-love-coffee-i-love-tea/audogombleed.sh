# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:fish
#
# Comprehensive tests for all help text types under fish

setup_file() {
    load '../_helpers/test-setup'
    _test_init_fish __CLI_CFG_EXEC_SILENT="y"
    # Install the dedicated help test config
    cp test/help-test-config.conf ~/.testcli.conf
}
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# --- global help ---

@test "fish: global help shows section headings" {
    run _fish_run '?'
    assert_success
    assert_line "  section alpha"
    assert_line "  section beta"
}

@test "fish: global help shows all commands with bracket notation" {
    run _fish_run '?'
    assert_success
    assert_line --partial "a[lpha]"
    assert_line --partial "b[eta]"
    assert_line --partial "g[amma]"
    assert_line --partial "d[elta]"
}

@test "fish: global help shows standalone command with inline help" {
    run _fish_run '?'
    assert_success
    assert_line --partial "s[tandalone]"
    assert_line --partial "standalone command help"
    refute_line "  standalone command help"
}

@test "fish: global help shows sub-command help text inline" {
    run _fish_run '?'
    assert_success
    assert_line --partial "o[ne]"
    assert_line --partial "command under alpha"
    assert_line --partial "t[wo]"
    assert_line --partial "another command under alpha"
}

@test "fish: global help shows detail comments below their command" {
    run _fish_run '?'
    assert_success
    assert_line --partial "detail line one for gamma four"
    assert_line --partial "detail line two for gamma four"
}

@test "fish: global help shows group-level detail comments" {
    run _fish_run '?'
    assert_success
    assert_line --partial "group detail line"
}

# --- section headings ---

@test "fish: section heading appears above its command group" {
    run _fish_run '?'
    assert_success
    local heading_line command_line
    heading_line=$(echo "$output" | grep -n "section alpha" | head -1 | cut -d: -f1)
    command_line=$(echo "$output" | grep -n "a\[lpha\]" | head -1 | cut -d: -f1)
    [ -n "$heading_line" ]
    [ -n "$command_line" ]
    [ "$heading_line" -lt "$command_line" ]
}

# --- command group help ---

@test "fish: command group help shows sub-commands" {
    run _fish_run alpha ?
    assert_success
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
}

# --- standalone command help ---

@test "fish: standalone command shows its own help when filtered" {
    run _fish_run standalone ?
    assert_success
    assert_line --partial "standalone command help"
}

# --- detail help ---

@test "fish: detail help shows for specific command" {
    run _fish_run gamma four ?
    assert_success
    assert_line --partial "detail line one for gamma four"
    assert_line --partial "detail line two for gamma four"
}

@test "fish: detail help shows command help text" {
    run _fish_run gamma four ?
    assert_success
    assert_line --partial "command under gamma with details"
}

@test "fish: command without details has no detail lines" {
    run _fish_run gamma five ?
    assert_success
    assert_line --partial "command under gamma without details"
    refute_line --partial "detail line"
}

@test "fish: group-level detail shows in group help" {
    run _fish_run delta ?
    assert_success
    assert_line --partial "group detail line"
}

# --- bracket notation ---

@test "fish: bracket notation marks minimum unambiguous prefix" {
    run _fish_run '?'
    assert_success
    assert_line --partial "a[lpha]"
    assert_line --partial "s[tandalone]"
}

@test "fish: sub-command bracket notation uses minimum prefix within group" {
    run _fish_run alpha ?
    assert_success
    assert_line --partial "o[ne]"
    assert_line --partial "t[wo]"
}

# --- argument placeholders ---

@test "fish: help shows argument placeholders for commands with args" {
    # Use example.conf which has the install command with arg placeholders
    cp example.conf ~/.testcli.conf
    sed -i '/^\[commands\]/i\
[env.fish]\
function create_cmd_words\
    echo "thievery"\
    echo "corporation"\
end\
function create_arg_options\
    echo "opt1"\
    echo "opt2"\
end\
' ~/.testcli.conf
    run _fish_run install -?
    assert_success
    assert_line --partial "<jar-file>"
    assert_line --partial "<mvn-coords>"
    assert_line --partial "<war-file>"
}
