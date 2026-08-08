# vim:et:ts=4:sw=4

#
#	Tests configuration options
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

@test "bash: backslashes in config values are preserved" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
export REGEX_PATTERN="\d+\.\d+"
[commands]
show-regex: printf '%s' $REGEX_PATTERN
CONF
    source ./testcli
    run ./testcli show-regex
    assert_success
    assert_output '\d+\.\d+'
}
