# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:fish
#
# Tests help triggers: ?, -h, -? under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: help trigger '?' shows all commands" {
    run _fish_run '?'
    assert_success
    assert_output --partial "[cho]"
}

@test "fish: help trigger '-h' shows all commands" {
    run _fish_run -h
    assert_success
    assert_output --partial "[cho]"
}

@test "fish: help trigger '-?' shows all commands" {
    run _fish_run -?
    assert_success
    assert_output --partial "[cho]"
}

@test "fish: help trigger 'command ?' shows command help" {
    run _fish_run install ?
    assert_success
    assert_output --partial "example of deeper structure"
}

@test "fish: help trigger 'command -h' shows command help" {
    run _fish_run install -h
    assert_success
    assert_output --partial "example of deeper structure"
}

@test "fish: help trigger shows argument placeholders" {
    run _fish_run install -?
    assert_success
    assert_line --partial "<jar-file>"
    assert_line --partial "<mvn-coords>"
}

@test "fish: help trigger shows command tree structure" {
    run _fish_run install -?
    assert_success
    assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
    assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
    assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
    assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}
