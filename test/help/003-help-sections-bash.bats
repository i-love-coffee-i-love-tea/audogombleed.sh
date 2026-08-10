# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:bash

#
# Tests help sections, section headings, and ## detail comments (bash)
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; cp example.conf ~/.testcli.conf; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load; }

# bats test_tags=id:bash-263
@test "bash: help shows group heading from # comment" {
    # The example.conf has "# example of deeper structure" before install
    run ./testcli install -?
    assert_success
    assert_line "  example of deeper structure"
}

# bats test_tags=id:bash-264
@test "bash: help shows command tree with bracket notation" {
    run ./testcli install -?
    assert_success
    assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
    assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
    assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
    assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}

# bats test_tags=id:bash-265
@test "bash: help shows argument placeholders in output" {
    run ./testcli install -?
    assert_success
    assert_line --partial "<jar-file>"
    assert_line --partial "<mvn-coords>"
    assert_line --partial "<war-file>"
}

# bats test_tags=id:bash-266
@test "bash: full help output shows all command groups" {
    run ./testcli ?
    assert_success
    # Should show various command groups
    assert_line --partial "[cho]"
    assert_line --partial "[nstall]"
}

# bats test_tags=id:bash-267
@test "bash: help for command group shows sub-commands" {
    run ./testcli list-argument -?
    assert_success
    # Help uses bracket notation: from-f[unction], from-v[ariable]
    assert_line --partial "s[tatic]"
    assert_line --partial "from-f[unction]"
    assert_line --partial "from-v[ariable]"
}

# bats test_tags=id:bash-268
@test "bash: help shows comments for command tree words" {
    # The example.conf has "# demonstration of list argument types" before list-argument
    run ./testcli list-argument -?
    assert_success
    assert_line --partial "demonstration of list argument types"
}

# bats test_tags=id:bash-269
@test "bash: help shows description for standalone top-level command" {
    # The example.conf has "# example to test failing command exit code" before false:
    # The help text should appear inline on the command line, not as a section heading
    run ./testcli ?
    assert_success
    # inline: 4-space indent + command + help text on same line
    assert_line --partial "fa[lse]"
    assert_line --partial "example to test failing command exit code"
    # NOT as a section heading (2-space prefix, separate line)
    refute_line "  example to test failing command exit code"
}
