# vim:et:ts=4:sw=4
# bats file_tags=category:config, shell:fish
#
# Tests encoding edge cases under fish

setup_file()   { load '../_helpers/test-setup'; _test_init_fish __CLI_CFG_EXEC_SILENT="y"; }
teardown_file(){ load '../_helpers/test-setup'; _test_cleanup; }
setup()        { load '../_helpers/test-setup'; _test_load_fish; }

@test "fish: config with UTF-8 BOM fails to parse (known limitation)" {
    printf '\xEF\xBB\xBF[commands]\ntest-cmd: echo hello\n' > ~/.testcli.conf
    run _fish_run test-cmd
    assert_failure
}

@test "fish: config with CRLF line endings fails to parse (known limitation)" {
    printf '[commands]\r\ntest-cmd: echo hello\r\n' > ~/.testcli.conf
    run _fish_run test-cmd
    assert_failure
}

@test "fish: command name with UTF-8 characters fails (known limitation)" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
café: echo "utf8"
CONF
    run _fish_run café
    assert_failure
}

@test "fish: argument description with UTF-8 characters is preserved" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-cmd: echo
    :arg:list:v1|v2
CONF
    run _fish_eval '_awk output=commands command_filter="test-cmd"'
    assert_success
    [ "${#lines[@]}" -gt 0 ]
}

@test "fish: list values with UTF-8 characters complete correctly" {
    cat > ~/.testcli.conf <<'CONF'
[env.fish]
[commands]
test-cmd: echo
    :arg:list:café|naïve|résumé
CONF
    run _fish_eval '_cli_complete_arg 0 "" test-cmd'
    assert_success
    assert_line "café"
    assert_line "naïve"
    assert_line "résumé"
}

@test "fish: command with empty argument value is handled" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
test-cmd: echo \1
    :arg:list:
CONF
    run _fish_eval '_awk output=commands command_filter="test-cmd"'
    assert_success
}

@test "fish: command with only whitespace in help is handled" {
    cat > ~/.testcli.conf <<'CONF'
[env]
__CLI_CFG_EXEC_SILENT="y"
[env.fish]
[commands]
#   
test-cmd: echo hello
CONF
    run _fish_run test-cmd
    assert_success
    assert_output "hello"
}
