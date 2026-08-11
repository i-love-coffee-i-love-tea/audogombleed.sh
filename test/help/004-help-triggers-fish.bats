# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:fish

#
#	Tests help triggers under fish: ?, -h, -?
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; cp example.conf ~/.testcli.conf; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

# bats test_tags=id:fish-312
@test "fish: help trigger ? shows all commands" {
    run _fish_run ?
    assert_success
    # Should show help output with command list
    # The output uses bracket notation like e[cho]
    assert_output --partial "[cho]"
}

# bats test_tags=id:fish-313
@test "fish: help trigger -h shows all commands" {
    run _fish_run -h
    assert_success
    assert_output --partial "[cho]"
}

# bats test_tags=id:fish-314
@test "fish: help trigger -? shows all commands" {
    run _fish_run -?
    assert_success
    assert_output --partial "[cho]"
}

# bats test_tags=id:fish-315
@test "fish: help trigger '?' shows all commands" {
    run _fish_run '?'
    assert_success
    assert_output --partial "[cho]"
}

# bats test_tags=id:fish-316
@test "fish: help trigger command ? shows command help" {
    run _fish_run install ?
    assert_success
    # The help output shows the command description
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:fish-317
@test "fish: help trigger command -h shows command help" {
    run _fish_run install -h
    assert_success
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:fish-318
@test "fish: help trigger command -? shows command help" {
    run _fish_run install -?
    assert_success
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:fish-319
@test "fish: help trigger command '?' shows command help" {
    run _fish_run install '?'
    assert_success
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:fish-320
@test "fish: help trigger shows argument placeholders" {
    run _fish_run install -?
    assert_success
    # Should show the argument format
    assert_line --partial "jar-file"
    assert_line --partial "mvn-coords"
}

# bats test_tags=id:fish-321
@test "fish: help trigger shows command tree structure" {
    run _fish_run install -?
    assert_success
    # Should show the tree structure with indentation
    assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
    assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
    assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
    assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}
