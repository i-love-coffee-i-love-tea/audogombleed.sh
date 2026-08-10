# vim:et:ts=4:sw=4
# bats file_tags=category:help, shell:zsh

#
#	Tests help triggers under zsh: ?, -h, -?
#

setup_file() {
    load '../_helpers/common-setup'
    _common_setup __CLI_CFG_EXEC_SILENT="y"
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

# bats test_tags=id:zsh-193
@test "zsh: help trigger ? shows all commands" {
    run _zsh_run ?
    assert_success
    assert_output --partial "[cho]"
}

# bats test_tags=id:zsh-194
@test "zsh: help trigger -h shows all commands" {
    run _zsh_run -h
    assert_success
    assert_output --partial "[cho]"
}

# bats test_tags=id:zsh-195
@test "zsh: help trigger -? shows all commands" {
    run _zsh_run -?
    assert_success
    assert_output --partial "[cho]"
}

# bats test_tags=id:zsh-196
@test "zsh: help trigger command ? shows command help" {
    run _zsh_run install ?
    assert_success
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:zsh-197
@test "zsh: help trigger command -h shows command help" {
    run _zsh_run install -h
    assert_success
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:zsh-198
@test "zsh: help trigger command -? shows command help" {
    run _zsh_run install -?
    assert_success
    assert_output --partial "example of deeper structure"
}

# bats test_tags=id:zsh-199
@test "zsh: help trigger shows argument placeholders" {
    run _zsh_run install -?
    assert_success
    assert_line --partial "jar-file"
    assert_line --partial "mvn-coords"
}

# bats test_tags=id:zsh-200
@test "zsh: help trigger shows command tree structure" {
    run _zsh_run install -?
    assert_success
    assert_line "    i[nstall] j[ar] f[rom] f[ile] <jar-file>"
    assert_line "    i[nstall] j[ar] f[rom] m[aven] <mvn-coords>"
    assert_line "    i[nstall] w[ar] f[rom] f[ile] <war-file>"
    assert_line "    i[nstall] w[ar] f[rom] m[aven] <mvn-coords>"
}
