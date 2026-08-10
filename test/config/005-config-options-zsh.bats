# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:zsh

#
#	Tests configuration options under zsh
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

# bats test_tags=id:zsh-077
@test "zsh: backslashes in config values are preserved" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
export REGEX_PATTERN="\d+\.\d+"
[commands]
show-regex: printf '%s' $REGEX_PATTERN
CONF
    source ./testcli
    run _zsh_run show-regex
    assert_success
    assert_output '\d+\.\d+'
}
