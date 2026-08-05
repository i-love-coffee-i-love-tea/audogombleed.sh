# vim:et:ts=4:sw=4

#
#	Tests help triggers under zsh: ?, -h, -?
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
	load 'zsh-helpers'
}

@test "zsh: help trigger ? shows all commands" {
    run _zsh_run ?
    assert_success
    assert_output --partial "[cho]"
}

@test "zsh: help trigger -h shows all commands" {
    run _zsh_run -h
    assert_success
    assert_output --partial "[cho]"
}

@test "zsh: help trigger -? shows all commands" {
    run _zsh_run -?
    assert_success
    assert_output --partial "[cho]"
}

@test "zsh: help trigger command ? shows command help" {
    run _zsh_run install ?
    assert_success
    assert_output --partial "example of deeper structure"
}

@test "zsh: help trigger command -h shows command help" {
    run _zsh_run install -h
    assert_success
    assert_output --partial "example of deeper structure"
}

@test "zsh: help trigger command -? shows command help" {
    run _zsh_run install -?
    assert_success
    assert_output --partial "example of deeper structure"
}

@test "zsh: help trigger shows argument placeholders" {
    run _zsh_run install -?
    assert_success
    assert_line --partial "jar-file"
    assert_line --partial "mvn-coords"
}

@test "zsh: help trigger shows command tree structure" {
    run _zsh_run install -?
    assert_success
    assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
    assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
    assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
    assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}
