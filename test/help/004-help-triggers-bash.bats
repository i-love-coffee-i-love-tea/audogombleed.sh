# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:bash

#
#	Tests help triggers: ?, -h, -?, \?
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; cp example.conf ~/.testcli.conf; }
teardown_file() { rm -f ./testcli ~/.testcli.conf 2>/dev/null; }
teardown() { load '../_helpers/test-setup'; _test_teardown; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-269
@test "help trigger: ? shows all commands" {
    run ./testcli ?
    assert_success
    # Should show help output with command list
    # The output uses bracket notation like e[cho]
    assert_output --partial "[cho]"
}

# bats test_tags=id:bash-270
@test "help trigger: -h shows all commands" {
    run ./testcli -h
    assert_success
    assert_output --partial "[cho]"
}

# bats test_tags=id:bash-271
@test "help trigger: -? shows all commands" {
    run ./testcli -?
    assert_success
    assert_output --partial "[cho]"
}

# bats test_tags=id:bash-272
@test "help trigger: \? shows all commands" {
    run ./testcli \?
    assert_success
    assert_output --partial "[cho]"
}

# bats test_tags=id:bash-273
@test "help trigger: command ? shows command help" {
    run ./testcli install ?
    assert_success
    # The help output shows the command description
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:bash-274
@test "help trigger: command -h shows command help" {
    run ./testcli install -h
    assert_success
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:bash-275
@test "help trigger: command -? shows command help" {
    run ./testcli install -?
    assert_success
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:bash-276
@test "help trigger: command \? shows command help" {
    run ./testcli install \?
    assert_success
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:bash-277
@test "help trigger: shows argument placeholders" {
    run ./testcli install -?
    assert_success
    # Should show the argument format
    assert_line --partial "jar-file"
    assert_line --partial "mvn-coords"
}

# bats test_tags=id:bash-278
@test "help trigger: shows command tree structure" {
    run ./testcli install -?
    assert_success
    # Should show the tree structure with indentation
    assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
    assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
    assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
    assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}
