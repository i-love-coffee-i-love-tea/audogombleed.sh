# vim:et:ts=4:sw=4

#
# Tests help sections, section headings, and ## detail comments (bash)
#

setup_file() {
    load 'common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
}
teardown_file() {
    load 'common-teardown'
    _common_teardown
}
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
}

@test "bash: help shows group heading from # comment" {
    # The example.conf has "# example of deeper structure" before install
    run ./testcli install -?
    assert_success
    assert_line "  example of deeper structure"
}

@test "bash: help shows command tree with bracket notation" {
    run ./testcli install -?
    assert_success
    assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
    assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
    assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
    assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}

@test "bash: help shows argument placeholders in output" {
    run ./testcli install -?
    assert_success
    assert_line --partial "<jar-file>"
    assert_line --partial "<mvn-coords>"
    assert_line --partial "<war-file>"
}

@test "bash: full help output shows all command groups" {
    run ./testcli ?
    assert_success
    # Should show various command groups
    assert_line --partial "[cho]"
    assert_line --partial "[nstall]"
}

@test "bash: help for command group shows sub-commands" {
    run ./testcli list-argument -?
    assert_success
    # Help uses bracket notation: from-f[unction], from-v[ariable]
    assert_line --partial "s[tatic]"
    assert_line --partial "from-f[unction]"
    assert_line --partial "from-v[ariable]"
}

@test "bash: help shows comments for command tree words" {
    # The example.conf has "# demonstration of list argument types" before list-argument
    run ./testcli list-argument -?
    assert_success
    assert_line --partial "demonstration of list argument types"
}

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
