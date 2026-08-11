# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:bash

#
#	Tests configuration options
#

setup_file()   { load '../_helpers/test-setup'; _test_init __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_bash; }

# bats test_tags=id:bash-099
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
