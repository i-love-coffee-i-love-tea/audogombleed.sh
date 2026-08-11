# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish

#
#	Tests configuration options under fish
#

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; cp "test/_configs/config/005-config-options-fish.conf" ~/.testcli.conf; }

@test "fish: backslashes in config values are preserved" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
export REGEX_PATTERN="\d+\.\d+"
[commands]
show-regex: printf '%s' $REGEX_PATTERN
CONF
    run _fish_run show-regex
    assert_success
    assert_output '\d+\.\d+'
}
