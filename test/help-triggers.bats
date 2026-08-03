# vim:et:ts=4:sw=4

#
#	Tests help triggers: ?, -h, -?, \?
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

@test "help trigger: ? shows all commands" {
    run ./testcli ?
    assert_success
    # Should show help output with command list
    # The output uses bracket notation like e[cho]
    assert_output --partial "[cho]"
}

@test "help trigger: -h shows all commands" {
    run ./testcli -h
    assert_success
    assert_output --partial "[cho]"
}

@test "help trigger: -? shows all commands" {
    run ./testcli -?
    assert_success
    assert_output --partial "[cho]"
}

@test "help trigger: \? shows all commands" {
    run ./testcli \?
    assert_success
    assert_output --partial "[cho]"
}

@test "help trigger: command ? shows command help" {
    run ./testcli install ?
    assert_success
    # The help output shows the command description
    assert_output --partial "example of deeper structure"
}

@test "help trigger: command -h shows command help" {
    run ./testcli install -h
    assert_success
    assert_output --partial "example of deeper structure"
}

@test "help trigger: command -? shows command help" {
    run ./testcli install -?
    assert_success
    assert_output --partial "example of deeper structure"
}

@test "help trigger: command \? shows command help" {
    run ./testcli install \?
    assert_success
    assert_output --partial "example of deeper structure"
}

@test "help trigger: shows argument placeholders" {
    run ./testcli install -?
    assert_success
    # Should show the argument format
    assert_line --partial "jar-file"
    assert_line --partial "mvn-coords"
}

@test "help trigger: shows command tree structure" {
    run ./testcli install -?
    assert_success
    # Should show the tree structure with indentation
    assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
    assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
    assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
    assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}
